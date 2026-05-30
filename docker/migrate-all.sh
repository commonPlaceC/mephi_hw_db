#!/bin/sh
set -e

FLYWAY_OPTS="-user=${POSTGRES_USER} -password=${POSTGRES_PASSWORD} -connectRetries=10"

for db in vehicle racing hotel employees; do
  echo "Migrating database: ${db}"
  flyway ${FLYWAY_OPTS} \
    -url="jdbc:postgresql://postgres:5432/${db}" \
    -locations="filesystem:/flyway/sql/${db}" \
    migrate
done

echo "All migrations completed successfully."
