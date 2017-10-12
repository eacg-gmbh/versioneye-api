#!/bin/bash

echo "Going to run all specs"
export RAILS_ENV="test"
echo "Rails mode: $RAILS_ENV"

bundle exec rspec spec/api/v2/projects_api_spec.rb:742

export RAILS_ENV="development"
echo "Rails mode: $RAILS_ENV"
