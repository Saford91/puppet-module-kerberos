require 'spec_helper'
describe 'kerberos' do
  
  context 'with defaults for all parameters' do
    let(:facts) { {:operatingsystem => 'Debian'} }
    it { should contain_class('kerberos') }
    it { should_not contain_class('kerberos::client') }
    it { should_not contain_class('kerberos::kdc::master') }
  end
end
