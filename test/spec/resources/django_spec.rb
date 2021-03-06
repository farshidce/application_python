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

require 'spec_helper'

describe PoiseApplicationPython::Resources::Django do
  describe PoiseApplicationPython::Resources::Django::Resource do
    describe '#local_settings' do
      subject { chef_run.application_django('/test').local_settings_content }

      context 'with defaults' do
        recipe(subject: false) do
          application_django '/test'
        end
        it { is_expected.to eq <<-SETTINGS }
# Generated by Chef for application_django[/test]

DEBUG = False

DATABASES = {"default":{}}
SETTINGS
      end # /context with defaults

      context 'with a URL' do
        recipe(subject: false) do
          application_django '/test' do
            database 'postgres://myuser@dbhost/myapp'
          end
        end
        it { is_expected.to eq <<-SETTINGS }
# Generated by Chef for application_django[/test]

DEBUG = False

DATABASES = {"default":{"URL":"postgres://myuser@dbhost/myapp","ENGINE":"django.db.backends.postgresql_psycopg2","NAME":"myapp","USER":"myuser","HOST":"dbhost"}}
SETTINGS
      end # /context with a URL

      context 'with an options block' do
        recipe(subject: false) do
          application_django '/test' do
            database do
              engine 'postgres'
              name 'myapp'
              user 'myuser'
              host 'dbhost'
            end
          end
        end
        it { is_expected.to eq <<-SETTINGS }
# Generated by Chef for application_django[/test]

DEBUG = False

DATABASES = {"default":{"ENGINE":"django.db.backends.postgresql_psycopg2","NAME":"myapp","USER":"myuser","HOST":"dbhost"}}
SETTINGS
      end # /context with an options block

      context 'with debug mode' do
        recipe(subject: false) do
          application_django '/test' do
            debug true
          end
        end
        it { is_expected.to eq <<-SETTINGS }
# Generated by Chef for application_django[/test]

DEBUG = True

DATABASES = {"default":{}}
SETTINGS
      end # /context with debug mode

      context 'with a single allowed host' do
        recipe(subject: false) do
          application_django '/test' do
            allowed_hosts 'example.com'
          end
        end
        it { is_expected.to eq <<-SETTINGS }
# Generated by Chef for application_django[/test]

ALLOWED_HOSTS = ["example.com"]

DEBUG = False

DATABASES = {"default":{}}
SETTINGS
      end # /context with a single allowed host

      context 'with multiple allowed hosts' do
        recipe(subject: false) do
          application_django '/test' do
            allowed_hosts %w{example.com www.example.com}
          end
        end
        it { is_expected.to eq <<-SETTINGS }
# Generated by Chef for application_django[/test]

ALLOWED_HOSTS = ["example.com","www.example.com"]

DEBUG = False

DATABASES = {"default":{}}
SETTINGS
      end # /context with multiple allowed hosts

      context 'with a secret key' do
        recipe(subject: false) do
          application_django '/test' do
            secret_key 'swordfish'
          end
        end
        it { is_expected.to eq <<-SETTINGS }
# Generated by Chef for application_django[/test]

DEBUG = False

DATABASES = {"default":{}}

SECRET_KEY = "swordfish"
SETTINGS
      end # /context with a secret key
    end # /describe #local_settings

    describe '#default_local_settings_path' do
      subject { chef_run.application_django('/test').send(:default_local_settings_path) }

      context 'with no settings.py' do
        recipe(subject: false) do
          application_django '/test' do
            def settings_module
              nil
            end
          end
        end
        it { is_expected.to be_nil }
      end # /context with no settings.py

      context 'with basic settings.py' do
        recipe(subject: false) do
          application_django '/test' do
            settings_module 'myapp.settings'
          end
        end
        it { is_expected.to eq '/test/myapp/local_settings.py' }
      end # /context with basic settings.py
    end # /describe #default_local_settings_path

    describe '#default_manage_path' do
      subject { chef_run.application_django('/test').send(:default_manage_path) }
      recipe(subject: false) do
        application_django '/test'
      end
      before do
        allow(chef_run.application_django('/test')).to receive(:find_file).with('manage.py').and_return('/test/manage.py')
      end

      it { is_expected.to eq '/test/manage.py' }
    end # /describe #default_manage_path

    describe '#default_settings_module' do
      let(:settings_path) { nil }
      subject { chef_run.application_django('/test').send(:default_settings_module) }
      recipe(subject: false) do
        application_django '/test'
      end
      before do
        allow(chef_run.application_django('/test')).to receive(:find_file).with('settings.py').and_return(settings_path)
      end

      context 'with no settings.py' do
        it { is_expected.to be_nil }
      end # /context with no settings.py

      context 'with simple settings.py' do
        let(:settings_path) { '/test/myapp/settings.py' }
        it { is_expected.to eq 'myapp.settings' }
      end # /context with simple settings.py
    end # /describe #default_settings_module

    describe '#default_wsgi_module' do
      let(:wsgi_path) { nil }
      subject { chef_run.application_django('/test').send(:default_wsgi_module) }
      recipe(subject: false) do
        application_django '/test'
      end
      before do
        allow(chef_run.application_django('/test')).to receive(:find_file).with('wsgi.py').and_return(wsgi_path)
      end

      context 'with no wsgi.py' do
        it { is_expected.to be_nil }
      end # /context with no wsgi.py

      context 'with simple wsgi.py' do
        let(:wsgi_path) { '/test/wsgi.py' }
        it { is_expected.to eq 'wsgi' }
      end # /context with simple wsgi.py
    end # /describe #default_wsgi_module

    describe '#find_file' do
      let(:files) { [] }
      recipe(subject: false) do
        application_django '/test'
      end
      subject { chef_run.application_django('/test').send(:find_file, 'myfile.py') }
      before do
        allow(Dir).to receive(:[]).and_call_original
        allow(Dir).to receive(:[]).with('/test/**/myfile.py').and_return(files)
      end

      context 'with no matching files' do
        it { is_expected.to be_nil }
      end # /context with no matching files

      context 'with one matching file' do
        let(:files) { %w{/test/myfile.py} }
        it { is_expected.to eq '/test/myfile.py' }
      end # /context with one matching file

      context 'with two matching files' do
        let(:files) { %w{/test/myfile.py /test/sub/myfile.py} }
        it { is_expected.to eq '/test/myfile.py' }
      end # /context with two matching files

      context 'with two matching files in a different order' do
        let(:files) { %w{/test/sub/myfile.py /test/myfile.py} }
        it { is_expected.to eq '/test/myfile.py' }
      end # /context with two matching files in a different order

      context 'with two matching files on the same level' do
        let(:files) { %w{/test/b/myfile.py /test/a/myfile.py} }
        it { is_expected.to eq '/test/a/myfile.py' }
      end # /context with two matching files on the same level
    end # /describe #find_file
  end # /describe PoiseApplicationPython::Resources::Django::Resource

  describe PoiseApplicationPython::Resources::Django::Provider do
    step_into(:application_django)
    context 'with default settings' do
      recipe do
        application_django '/test' do
          # Hardwire all paths so it doesn't have to search.
          manage_path 'manage.py'
          settings_module 'myapp.settings'
          wsgi_module 'wsgi'
        end
      end

      it { is_expected.to run_python_execute('manage.py collectstatic --noinput') }
      it { is_expected.to_not run_python_execute('manage.py syncdb --noinput') }
      it { is_expected.to_not run_python_execute('manage.py migrate --noinput') }
      it { is_expected.to render_file('/test/myapp/local_settings.py') }
    end # /context with default settings

    context 'with syncdb' do
      recipe do
        application_django '/test' do
          # Hardwire all paths so it doesn't have to search.
          manage_path 'manage.py'
          settings_module 'myapp.settings'
          syncdb true
          wsgi_module 'wsgi'
        end
      end

      it { is_expected.to run_python_execute('manage.py collectstatic --noinput') }
      it { is_expected.to run_python_execute('manage.py syncdb --noinput') }
      it { is_expected.to_not run_python_execute('manage.py migrate --noinput') }
    end # /context with syncdb

    context 'with migrate' do
      recipe do
        application_django '/test' do
          # Hardwire all paths so it doesn't have to search.
          manage_path 'manage.py'
          migrate true
          settings_module 'myapp.settings'
          wsgi_module 'wsgi'
        end
      end

      it { is_expected.to run_python_execute('manage.py collectstatic --noinput') }
      it { is_expected.to_not run_python_execute('manage.py syncdb --noinput') }
      it { is_expected.to run_python_execute('manage.py migrate --noinput') }
      it { is_expected.to render_file('/test/myapp/local_settings.py') }
    end # /context with migrate
  end # /describe PoiseApplicationPython::Resources::Django::Provider
end
