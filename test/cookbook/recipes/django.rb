#
# Copyright 2015-2016, Noah Kantrowitz
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
#

include_recipe 'build-essential'
include_recipe 'poise-python'

application '/opt/test_django' do
  git 'https://github.com/poise/test_django.git'
  python 'pypy3-5.5'
  virtualenv
  pip_requirements
  django do
    database 'sqlite:///test_django.db'
    migrate true
  end
  gunicorn do
    port 9000
  end
end
