#!/bin/bash
rm ./test.db
rm ./source/migrations/*.d
rm .orm_snapshot.json
# empty out source/migrations/manifest
echo "" > source/migrations/manifest
