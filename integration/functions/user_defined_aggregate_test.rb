# encoding: utf-8

#--
# Copyright 2013-2015 DataStax, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

require File.dirname(__FILE__) + '/../integration_test_case.rb'

class UserDefinedAggregateTest < IntegrationTestCase
  def setup
    @@ccm_cluster.setup_schema(<<-CQL)
    CREATE KEYSPACE simplex WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
    USE simplex;
    CREATE FUNCTION sum_int(key int, val int)
                    CALLED ON NULL INPUT
                    RETURNS int
                    LANGUAGE javascript AS 'key + val';
    CREATE FUNCTION state_group_and_sum(state map<int, int>, star_rating int)
                    CALLED ON NULL INPUT
                    RETURNS map<int, int>
                    LANGUAGE java
                    AS 'if (state.get(star_rating) == null) state.put(star_rating, 1); else state.put(star_rating, ((Integer) state.get(star_rating)) + 1); return state;';
    CREATE FUNCTION percent_stars(state map<int,int>)
                    RETURNS NULL ON NULL INPUT
                    RETURNS map<int, int>
                    LANGUAGE java AS 'Integer sum = 0; for(Object k : state.keySet()) { sum = sum + (Integer) state.get((Integer) k); } java.util.Map<Integer, Integer> results = new java.util.HashMap<Integer, Integer>(); for(Object k : state.keySet()) { results.put((Integer) k, ((Integer) state.get((Integer) k))*100 / sum); } return results;';
    CREATE FUNCTION extend_list(s list<text>, i int)
                    CALLED ON NULL INPUT
                    RETURNS list<text>
                    LANGUAGE java AS 'if (i != null) s.add(i.toString()); return s;';
    CREATE FUNCTION update_map(s map<int, int>, i int)
                    RETURNS NULL ON NULL INPUT
                    RETURNS map<int, int>
                    LANGUAGE java AS 's.put(new Integer(i), new Integer(i)); return s;';
    CREATE FUNCTION sum_int_two(s int, i int, j int)
                    RETURNS NULL ON NULL INPUT
                    RETURNS int
                    LANGUAGE javascript AS 's + i + j';
    CQL
  end

  # Test raising error for nonexistent UDA
  #
  # test_raise_error_on_nonexisting_state_function tests the driver properly routes the Cassandra error for a
  # nonexistent state function. It attempts to create a UDA with a nonexistent state function and verifies that a
  # Cassandra::Errors::InvalidError is thrown.
  #
  # @expected_errors [Cassandra::Errors::InvalidError] When an the a nonexistent state function is used.
  #
  # @since 3.0.0
  # @jira_ticket RUBY-108
  # @expected_result a Cassandra::Errors::InvalidError should be raised
  #
  # @test_category functions:uda
  #
  def test_raise_error_on_nonexisting_state_function
    skip("UDAs are only available in C* after 2.2") if CCM.cassandra_version < '2.2.0'

    cluster = Cassandra.cluster
    session = cluster.connect("simplex")

    assert_raises(Cassandra::Errors::InvalidError) do
      session.execute("CREATE AGGREGATE sum_agg(int)
                      SFUNC non_existent
                      STYPE int
                      INITCOND 0"
      )
    end
  ensure
    cluster && cluster.close
  end

  # Test for creating a basic UDA
  #
  # test_can_create_udas tests that a UDA can be created and its metadata is populated appropriately. It first creates
  # a simple UDA and verifies that it appears in the keyspace metadata. then verifies each of the UDA's metadata.
  #
  # @since 3.0.0
  # @jira_ticket RUBY-108
  # @expected_result A UDA should be created and its metadata should be populated.
  #
  # @test_category functions:uda
  #
  def test_can_create_udas
    skip("UDAs are only available in C* after 2.2") if CCM.cassandra_version < '2.2.0'

    cluster = Cassandra.cluster(schema_refresh_delay: 0.1, schema_refresh_timeout: 0.1)
    session = cluster.connect("simplex")

    assert_empty cluster.keyspace("simplex").aggregates

    assert cluster.keyspace("simplex").has_function?("sum_int")
    state_function = cluster.keyspace("simplex").function("sum_int")

    session.execute("CREATE AGGREGATE sum_agg(int)
                    SFUNC sum_int
                    STYPE int
                    INITCOND 0"
    )

    sleep(2)
    assert cluster.keyspace("simplex").has_aggregate?("sum_agg")
    aggregate = cluster.keyspace("simplex").aggregate("sum_agg")

    assert_equal "sum_agg", aggregate.name
    assert_equal Cassandra::Types.int, aggregate.type
    assert_equal [Cassandra::Types.int], aggregate.argument_types
    assert_equal Cassandra::Types.int, aggregate.state_type
    assert_equal "0", aggregate.initial_state
    assert_equal state_function, aggregate.state_function
  ensure
    cluster && cluster.close
  end

  # Test for creating a UDA with a finalfunc
  #
  # test_udas_with_finalfunc tests that a UDA can be created with a finalfunc. It first creates a UDA with a finalfunc
  # and verifies that it appears in the keyspace metadata. then verifies each of the UDA's metadata, including its
  # metadata about its finalfunc.
  #
  # @since 3.0.0
  # @jira_ticket RUBY-108
  # @expected_result A UDA should be created and its metadata should be populated.
  #
  # @test_category functions:uda
  #
  def test_udas_with_finalfunc
    skip("UDAs are only available in C* after 2.2") if CCM.cassandra_version < '2.2.0'

    cluster = Cassandra.cluster(schema_refresh_delay: 0.1, schema_refresh_timeout: 0.1)
    session = cluster.connect("simplex")

    # Initcond, finalfunc
    assert cluster.keyspace("simplex").has_function?("state_group_and_sum")
    state_function = cluster.keyspace("simplex").function("state_group_and_sum")
    assert cluster.keyspace("simplex").has_function?("percent_stars")
    final_function = cluster.keyspace("simplex").function("percent_stars")

    session.execute("CREATE OR REPLACE AGGREGATE group_and_sum(int)
                    SFUNC state_group_and_sum
                    STYPE map<int, int>
                    FINALFUNC percent_stars
                    INITCOND {}"
    )

    sleep(2)
    assert cluster.keyspace("simplex").has_aggregate?("group_and_sum")
    aggregate = cluster.keyspace("simplex").aggregate("group_and_sum")

    assert_equal "group_and_sum", aggregate.name
    assert_equal Cassandra::Types.map(Cassandra::Types.int, Cassandra::Types.int), aggregate.type
    assert_equal [Cassandra::Types.int], aggregate.argument_types
    assert_equal Cassandra::Types.map(Cassandra::Types.int, Cassandra::Types.int), aggregate.state_type
    assert_equal "{}", aggregate.initial_state
    assert_equal state_function, aggregate.state_function
    assert_equal final_function, aggregate.final_function

    # No initcond, finalfunc
    session.execute("CREATE OR REPLACE AGGREGATE group_and_sum(int)
                    SFUNC state_group_and_sum
                    STYPE map<int, int>
                    FINALFUNC percent_stars"
    )

    sleep(2)
    assert cluster.keyspace("simplex").has_aggregate?("group_and_sum")
    aggregate = cluster.keyspace("simplex").aggregate("group_and_sum")

    assert_equal nil, aggregate.initial_state
  ensure
    cluster && cluster.close
  end

  # Test for creating a UDA with different initconds
  #
  # test_uda_initconds tests that UDAs can be created with different types of initconds, and their metadata is updated
  # properly. It creates simple UDAs with: no initconds, int, list<text>, and map<int,int> and verifies in each UDA
  # that the initcond metadata is updated properly.
  #
  # @since 3.0.0
  # @jira_ticket RUBY-108
  # @expected_result UDAs should be created with various initconds and updated metadata
  #
  # @test_category functions:uda
  #
  def test_uda_initconds
    skip("UDAs are only available in C* after 2.2") if CCM.cassandra_version < '2.2.0'

    cluster = Cassandra.cluster(schema_refresh_delay: 0.1, schema_refresh_timeout: 0.1)
    session = cluster.connect("simplex")

    assert cluster.keyspace("simplex").has_function?("sum_int")
    assert cluster.keyspace("simplex").has_function?("extend_list")
    assert cluster.keyspace("simplex").has_function?("update_map")

    # No initcond
    session.execute("CREATE AGGREGATE sum_agg(int)
                    SFUNC sum_int
                    STYPE int"
    )

    sleep(2)
    assert cluster.keyspace("simplex").has_aggregate?("sum_agg")
    aggregate = cluster.keyspace("simplex").aggregate("sum_agg")
    assert_equal nil, aggregate.initial_state

    # int
    session.execute("CREATE AGGREGATE sum_agg2(int)
                    SFUNC sum_int
                    STYPE int
                    INITCOND -1"
    )

    sleep(2)
    assert cluster.keyspace("simplex").has_aggregate?("sum_agg2")
    aggregate = cluster.keyspace("simplex").aggregate("sum_agg2")
    assert_equal "-1", aggregate.initial_state

    # list<text>
    session.execute("CREATE AGGREGATE extend_list_agg(int)
                    SFUNC extend_list
                    STYPE list<text>
                    INITCOND ['1', '2']"
    )

    sleep(2)
    assert cluster.keyspace("simplex").has_aggregate?("extend_list_agg")
    aggregate = cluster.keyspace("simplex").aggregate("extend_list_agg")
    assert_equal "['1', '2']", aggregate.initial_state

    # map<int,int>
    session.execute("CREATE AGGREGATE update_map_agg(int)
                    SFUNC update_map
                    STYPE map<int, int>
                    INITCOND {1: 2, 3: 4}"
    )

    sleep(2)
    assert cluster.keyspace("simplex").has_aggregate?("update_map_agg")
    aggregate = cluster.keyspace("simplex").aggregate("update_map_agg")
    assert_equal "{1: 2, 3: 4}", aggregate.initial_state
  ensure
    cluster && cluster.close
  end

  # Test for creating two UDAs with the same name, but different types
  #
  # test_can_create_uda_same_name_different_types tests that a UDA is identified by its signature, which is the
  # combination of its name and its argument types. It first creates a UDA and retrieves it, verifying that the UDA's
  # signature contains the correct argument types. It then creates another UDA with the same name, but different
  # arguments. When retrieving the function, the first one is retrieved so the argument types are of the first UDA.
  #
  # @since 3.0.0
  # @jira_ticket RUBY-108
  # @expected_result Two UDAs should be created, with the same name but different types
  #
  # @test_category functions:uda
  #
  def test_can_create_uda_same_name_different_types
    skip("UDAs are only available in C* after 2.2") if CCM.cassandra_version < '2.2.0'

    cluster = Cassandra.cluster(schema_refresh_delay: 0.1, schema_refresh_timeout: 0.1)
    session = cluster.connect("simplex")

    assert cluster.keyspace("simplex").has_function?("sum_int")
    assert cluster.keyspace("simplex").has_function?("sum_int_two")

    session.execute("CREATE AGGREGATE sum_agg(int)
                    SFUNC sum_int
                    STYPE int
                    INITCOND 0"
    )

    sleep(2)
    assert cluster.keyspace("simplex").has_aggregate?("sum_agg")
    aggregate = cluster.keyspace("simplex").aggregate("sum_agg")
    assert_equal [Cassandra::Types.int], aggregate.argument_types

    session.execute("CREATE AGGREGATE sum_agg(int,int)
                    SFUNC sum_int_two
                    STYPE int
                    INITCOND 0"
    )

    sleep(2)
    assert cluster.keyspace("simplex").has_aggregate?("sum_agg")
    aggregate = cluster.keyspace("simplex").aggregate("sum_agg")
    assert_equal [Cassandra::Types.int], aggregate.argument_types
  ensure
    cluster && cluster.close
  end

  # Test for maintaining metadata during keyspace changes
  #
  # test_aggregates_follow_keyspace_alter tests that UDA metadata is not change when there are other changes to the
  # keyspace metadata. It first creates a simple UDA and saves the keyspace UDA metadata. It then alters the keyspace
  # with durable_writes=false. Finally it verifies that there is no delta between the two aggregate metadata in the
  # keyspace.
  #
  # @since 3.0.0
  # @jira_ticket RUBY-108
  # @expected_result UDA metadata should not be changed due to keyspace changes
  #
  # @test_category functions:uda
  #
  def test_aggregates_follow_keyspace_alter
    skip("UDFs are only available in C* after 2.2") if CCM.cassandra_version < '2.2.0'

    cluster = Cassandra.cluster(schema_refresh_delay: 0.1, schema_refresh_timeout: 0.1)
    session = cluster.connect("simplex")

    assert cluster.keyspace("simplex").has_function?("sum_int")

    session.execute("CREATE AGGREGATE sum_agg(int)
                    SFUNC sum_int
                    STYPE int
                    INITCOND 0"
    )

    sleep(2)
    original_aggregates = cluster.keyspace("simplex").aggregates

    session.execute("ALTER KEYSPACE simplex WITH durable_writes = false")
    new_aggregates = cluster.keyspace("simplex").aggregates
    assert_equal original_aggregates, new_aggregates

    session.execute("ALTER KEYSPACE simplex WITH durable_writes = true")
  ensure
    cluster && cluster.close
  end

  # Test for serialization and deserialization of UDAs
  #
  # test_aggregates_serialization_deserialization tests that the driver properly serializes and deserializes UDAs. It
  # creates a UDA which calculates star_ratings of an item, and aggregates them into buckets based on star_rating. It
  # also creates a table and inserts some data. Finally, it calls the UDA to aggregate on the column on the 'star_rating'
  # and verifies that the star_ratings are aggregated and returned via the driver.
  #
  # @since 3.0.0
  # @jira_ticket RUBY-108
  # @expected_result the UDA should be created, and should return the proper aggregation of star_rating
  #
  # @test_category functions:uda
  #
  def test_aggregates_serialization_deserialization
    skip("UDFs are only available in C* after 2.2") if CCM.cassandra_version < '2.2.0'

    cluster = Cassandra.cluster
    session = cluster.connect("simplex")

    assert cluster.keyspace("simplex").has_function?("state_group_and_sum")
    assert cluster.keyspace("simplex").has_function?("percent_stars")

    # Create the UDA
    session.execute("CREATE OR REPLACE AGGREGATE group_and_sum(int)
                    SFUNC state_group_and_sum
                    STYPE map<int, int>
                    FINALFUNC percent_stars
                    INITCOND {}"
    )

    # Create the table
    session.execute("CREATE TABLE reviews (item_id uuid, time timeuuid, star_rating int,
                    PRIMARY KEY (item_id, time)) WITH CLUSTERING ORDER BY (time DESC)")

    # Insert data
    insert = session.prepare("INSERT INTO reviews (item_id, time, star_rating) VALUES (?, ?, ?)")
    item_id = Cassandra::Uuid.new('0979dea5-5a65-446d-bad6-27d04d5dd8a5')
    generator = Cassandra::Uuid::Generator.new
    session.execute(insert, arguments: [item_id, generator.now, 5])
    session.execute(insert, arguments: [item_id, generator.now, 4])
    session.execute(insert, arguments: [item_id, generator.now, 4])
    session.execute(insert, arguments: [item_id, generator.now, 3])
    session.execute(insert, arguments: [item_id, generator.now, 3])
    session.execute(insert, arguments: [item_id, generator.now, 4])
    session.execute(insert, arguments: [item_id, generator.now, 2])
    session.execute(insert, arguments: [item_id, generator.now, 5])
    session.execute(insert, arguments: [item_id, generator.now, 4])
    session.execute(insert, arguments: [item_id, generator.now, 5])

    # Verify UDA
    results = session.execute("SELECT group_and_sum(star_rating) FROM reviews WHERE item_id=0979dea5-5a65-446d-bad6-27d04d5dd8a5")
    expected = {2 => 10, 3 => 20, 4 => 40, 5 => 30}
    assert_equal expected, results.first["simplex.group_and_sum(star_rating)"]
  ensure
    cluster && cluster.close
  end

end