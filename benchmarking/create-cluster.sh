#!/bin/bash

create=false
insert=false
help=false



while getopts "hci" opt; do
    case $opt in
        c) create=true ;;
        i) insert=true ;;
        :) echo "Option -$OPTARG requires an argument." >&2 ; help=true ;;
        *) help=true ;; # Wrong argument == print help
    esac
done



# Print help if asked
if [ $help = true ] ; then
    echo "Usage: $0 [option...]
    Prepare a ccm cluster called 'test-cluster' for benchmarks.

Options:
    -c      Create the cluster
    -i      Insert data in the cluster (including create keyspace)" \
        >&2
    exit
fi
shift $((OPTIND-1))



if [ $create = true ] ; then
    ccm create -n 3 -v git:cassandra-2.0.10 -i 127.0.0. -s -b test-cluster
else
    echo "# '-c' argument not used, skipping cluster creation." >&2
fi



if [ $insert = true ] ; then
    echo "CREATE KEYSPACE simplex WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3};" | ccm node1 cqlsh

    echo "CREATE TABLE simplex.songs (
        id uuid PRIMARY KEY,
        title text,
        album text,
        artist text,
        tags set<text>,
        data blob
      );" | ccm node1 cqlsh

    echo "USE simplex;
      INSERT INTO songs (id, title, album, artist, tags)
      VALUES (
         756716f7-2e54-4715-9f00-91dcbea6cf50,
         'La Petite Tonkinoise',
         'Bye Bye Blackbird',
         'Joséphine Baker',
         {'jazz', '2013'})
      ;
      INSERT INTO songs (id, title, album, artist, tags)
      VALUES (
         f6071e72-48ec-4fcb-bf3e-379c8a696488,
         'Die Mösch',
         'In Gold',
         'Willi Ostermann',
         {'kölsch', '1996', 'birds'}
      );
      INSERT INTO songs (id, title, album, artist, tags)
      VALUES (
         fbdf82ed-0063-4796-9c7c-a3d4f47b4b25,
         'Memo From Turner',
         'Performance',
         'Mick Jager',
         {'soundtrack', '1991'}
      );" | ccm node1 cqlsh

    # cqlsh -k simplex -f ../features/support/cql/schema/songs.cql
    # cqlsh -k simplex -f ../features/support/cql/data/songs.cql
else
    echo "# '-i' argument not used, skipping schema creation and content insertion." >&2
fi

