require 'spec_helper'
describe 'srcds' do

  context 'with defaults for all parameters' do
    it { should contain_class('srcds') }
  end
end
