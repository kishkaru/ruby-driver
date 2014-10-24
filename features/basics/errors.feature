Feature: Cassandra Ruby Driver Errors

  The Ruby driver will error out and provide error messages for known error types.

  Background:
    Given a running cassandra cluster

  Scenario: Errors when syntax correct but invalid query
    Given the following example:
      """ruby
      require 'cassandra'

      cluster = Cassandra.cluster

      begin
        session = cluster.connect("badkeyspace")
      rescue => e
        puts "#{e.class.name}: #{e.message}"
      end
      """
    When it is executed
    Then its output should contain:
      """
      Cassandra::Errors::InvalidError: Keyspace 'badkeyspace' does not exist
      """

  Scenario: Errors when user doesn't have permission to perform query
    Given the following example:
      """ruby
      require 'cassandra'

      cluster = Cassandra.cluster
      session = cluster.connect("system")

      begin
        session.execute("CREATE TABLE users (user_id INT PRIMARY KEY)")
      rescue => e
        puts "#{e.class.name}: #{e.message}"
      end
      """
    When it is executed
    Then its output should contain:
      """
      Cassandra::Errors::UnauthorizedError: system keyspace is not user-modifiable.
      """

  Scenario: Errors when invalid configuration of query
    Given the following example:
      """ruby
      require 'cassandra'

      cluster = Cassandra.cluster
      session = cluster.connect()

      begin
        session.execute("DROP KEYSPACE badkeyspace")
      rescue => e
        puts "#{e.class.name}: #{e.message}"
      end
      """
    When it is executed
    Then its output should contain:
      """
      Cassandra::Errors::ConfigurationError: Cannot drop non existing keyspace 'badkeyspace'.
      """

  Scenario: Errors when creating resource that already exists
    Given the following schema:
      """cql
      CREATE KEYSPACE simplex WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3};
      """
    And the following example:
      """ruby
      require 'cassandra'

      cluster = Cassandra.cluster
      session = cluster.connect()

      begin
        session.execute("CREATE KEYSPACE simplex WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3}")
      rescue => e
        puts "#{e.class.name}: #{e.message}"
      end
      """
    When it is executed
    Then its output should contain:
      """
      Cassandra::Errors::AlreadyExistsError: Cannot add existing keyspace "simplex"
      """

  Scenario: Errors when CQL has invalid syntax
    Given the following schema:
      """cql
      CREATE KEYSPACE simplex WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3};
      USE simplex;
      CREATE TABLE users (user_id BIGINT PRIMARY KEY, first VARCHAR, last VARCHAR, age BIGINT);
      """
    And the following example:
      """ruby
      require 'cassandra'

      cluster = Cassandra.cluster
      session = cluster.connect("simplex")

      begin
        session.execute("INSERT INTO users (user_id, first, last, age)")
      rescue => e
        puts "#{e.class.name}: #{e.message}"
      end
      """
    When it is executed
    Then its output should contain:
      """
      Cassandra::Errors::SyntaxError: line 0:-1 mismatched input '<EOF>' expecting K_VALUES\n
      """

  @auth
  Scenario: Errors during authentication
    Given a running cassandra cluster with authentication enabled
    And the following example:
      """ruby
      require 'cassandra'

      begin
        cluster = Cassandra.cluster(
                    username: 'invalidname',
                    password: 'badpassword'
                  )
      rescue => e
        puts "#{e.class.name}: #{e.message}"
      end
      """
    When it is executed
    Then its output should contain:
      """
      Cassandra::Errors::AuthenticationError: Username and/or password are incorrect
      """

  Scenario: Errors when all hosts down
    Given all nodes are down
    And the following example:
      """ruby
      require 'cassandra'

      begin
        cluster = Cassandra.cluster
        session = cluster.connect()
      rescue => e
        puts "#{e.class.name}: #{e.message}"
      end
      """
    When it is executed
    Then its output should contain:
      """
      Cassandra::Errors::NoHostsAvailable: All attempted hosts failed: 127.0.0.1
      """

  @netblock
  Scenario: Errors when cluster connection times out
    Given node 1 is unreachable
    And the following example:
      """ruby
      require 'cassandra'

      begin
        cluster = Cassandra.cluster(connect_timeout: 1)
        session = cluster.connect()
      rescue => e
        puts "#{e.class.name}: #{e.message}"
      end
      """
    When it is executed
    Then its output should contain:
      """
      Cassandra::Errors::IOError: Could not connect to 127.0.0.1:9042 within 1s
      """

  Scenario: Errors when can't achieve desired consistency
    Given the following schema:
      """cql
      CREATE KEYSPACE simplex WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3};
      USE simplex;
      CREATE TABLE users (user_id BIGINT PRIMARY KEY, first VARCHAR, last VARCHAR, age BIGINT);
      """
    And the following example:
      """ruby
      require 'cassandra'

      cluster = Cassandra.cluster
      session = cluster.connect("simplex")
      
      query = "INSERT INTO users (user_id, first, last, age) VALUES (0, 'John', 'Doe', 40)"
      begin
        session.execute(query, :consistency => :all)
      rescue => e
        puts "#{e.class.name}: #{e.message}"
      end
      """
    When node 3 stops
    And it is executed
    Then its output should contain:
      """
      Cassandra::Errors::UnavailableError: Cannot achieve consistency level ALL
      """

  @netblock
  Scenario: Errors when session query times out
    Given the following schema:
      """cql
      CREATE KEYSPACE simplex WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
      USE simplex;
      CREATE TABLE users (user_id BIGINT PRIMARY KEY, first VARCHAR, last VARCHAR, age BIGINT);
      INSERT INTO users (user_id, first, last, age) VALUES (0, 'John', 'Doe', 40);
      INSERT INTO users (user_id, first, last, age) VALUES (1, 'Mary', 'Doe', 35);
      INSERT INTO users (user_id, first, last, age) VALUES (2, 'Agent', 'Smith', 32);
      """
    And the following example:
      """ruby
      require 'cassandra' 

      cluster = Cassandra.cluster(retry_policy: Cassandra::Retry::Policies::Fallthrough.new)
      session = cluster.connect("simplex")
      
      $stdout.puts("=== START ===")
      $stdout.flush
      until (input = $stdin.gets).nil? # block until closed
        query = input.chomp
        begin
          results = session.execute(query, :consistency => :all, :timeout => 1)
          puts results.inspect
          execution_info = results.execution_info
          $stdout.puts("Query #{query.inspect} fulfilled by #{execution_info.hosts}")
        rescue => e
          $stdout.puts("#{e.class.name}: #{e.message}")
        end
        $stdout.flush
      end
      $stdout.puts("=== STOP ===")
      $stdout.flush
      """
    When it is running interactively
    And I wait for its output to contain "START"
    And node 3 is unreachable
    And I type "SELECT * FROM simplex.users WHERE user_id=0"
    And I close the stdin stream
    Then its output should contain:
      """
      Cassandra::Errors::TimeoutError: Timed out
      """

  @netblock
  Scenario: Errors when server read times out
    Given the following schema:
      """cql
      CREATE KEYSPACE simplex WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
      USE simplex;
      CREATE TABLE users (user_id BIGINT PRIMARY KEY, first VARCHAR, last VARCHAR, age BIGINT);
      INSERT INTO users (user_id, first, last, age) VALUES (0, 'John', 'Doe', 40);
      INSERT INTO users (user_id, first, last, age) VALUES (1, 'Mary', 'Doe', 35);
      INSERT INTO users (user_id, first, last, age) VALUES (2, 'Agent', 'Smith', 32);
      """
    And the following example:
      """ruby
      require 'cassandra'

      cluster = Cassandra.cluster(retry_policy: Cassandra::Retry::Policies::Fallthrough.new)
      session = cluster.connect("simplex")
      
      $stdout.puts("=== START ===")
      $stdout.flush
      until (input = $stdin.gets).nil? # block until closed
        query = input.chomp
        begin
          results = session.execute(query, :consistency => :all)
          puts results.inspect
          execution_info = results.execution_info
          $stdout.puts("Query #{query.inspect} fulfilled by #{execution_info.hosts}")
        rescue => e
          $stdout.puts("#{e.class.name}: #{e.message}")
        end
        $stdout.flush
      end
      $stdout.puts("=== STOP ===")
      $stdout.flush
      """
    When it is running interactively
    And I wait for its output to contain "START"
    And node 3 is unreachable
    And I type "SELECT * FROM simplex.users WHERE user_id IN (1,2,3,4,5,6,7,8,9,0,11,12,13,14,15,16,17,18,19,20)"
    And I close the stdin stream
    Then its output should contain:
      """
      Cassandra::Errors::ReadTimeoutError: Operation timed out - received only 0 responses.
      """
  
  @netblock
  Scenario: Errors when server write times out
    Given the following schema:
      """cql
      CREATE KEYSPACE simplex WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
      USE simplex;
      CREATE TABLE users (user_id BIGINT PRIMARY KEY, first VARCHAR, last VARCHAR, age BIGINT);
      INSERT INTO users (user_id, first, last, age) VALUES (0, 'John', 'Doe', 40);
      INSERT INTO users (user_id, first, last, age) VALUES (1, 'Mary', 'Doe', 35);
      INSERT INTO users (user_id, first, last, age) VALUES (2, 'Agent', 'Smith', 32);
      """
    And the following example:
      """ruby
      require 'cassandra'

      cluster = Cassandra.cluster(retry_policy: Cassandra::Retry::Policies::Fallthrough.new)
      session = cluster.connect("simplex")
      
      $stdout.puts("=== START ===")
      $stdout.flush
      until (input = $stdin.gets).nil? # block until closed
        query = input.chomp
        begin
          results = session.execute(query, :consistency => :all)
          puts results.inspect
          execution_info = results.execution_info
          $stdout.puts("Query #{query.inspect} fulfilled by #{execution_info.hosts}")
        rescue => e
          $stdout.puts("#{e.class.name}: #{e.message}")
        end
        $stdout.flush
      end
      $stdout.puts("=== STOP ===")
      $stdout.flush
      """
    When it is running interactively
    And I wait for its output to contain "START"
    And node 3 is unreachable
    And I type "UPDATE simplex.users SET age=41 WHERE user_id=0"
    And I close the stdin stream
    Then its output should contain:
      """
      Cassandra::Errors::WriteTimeoutError: Operation timed out - received only 0 responses.
      """
