require_relative '../lib/dns_data'

RSpec.describe(DnsData) do
  subject(:dns) { DnsData.new }

  describe "#dump" do
    before do
      dns.forward('a.example.com', :A, '127.0.0.1')
      dns.reverse('127.0.0.1', 'a.example.com')
      dns.cname('cname.example.com', 'a.example.com')

      dns.forward('a.example.org', :A, '127.0.0.3')
      dns.forward('a.example.org', :A, '127.0.0.2')
      dns.reverse('127.0.0.2', 'a.example.org')

      dns.forward('a.example.net', :A, '127.0.0.4')
    end

    subject(:zones) { dns.dump(%w(example.com example.org 0.0.127.in-addr.arpa)) }

    it "dumps records" do
      expect(zones.keys.sort).to eq(%w(. example.com example.org 0.0.127.in-addr.arpa).sort)
      expect(zones.fetch('example.com')).to eq([
        {'fqdn' => 'a.example.com', 'type' => 'A', 'rr' => ['127.0.0.1']},
        {'fqdn' => 'cname.example.com', 'type' => 'CNAME', 'rr' => ['a.example.com.']},
      ])
      expect(zones.fetch('example.org')).to eq([
        {'fqdn' => 'a.example.org', 'type' => 'A', 'rr' => ['127.0.0.2', '127.0.0.3']},
      ])
      expect(zones.fetch('0.0.127.in-addr.arpa')).to eq([
        {'fqdn' => '1.0.0.127.in-addr.arpa', 'type' => 'PTR', 'rr' => ['a.example.com.']},
        {'fqdn' => '2.0.0.127.in-addr.arpa', 'type' => 'PTR', 'rr' => ['a.example.org.']},
      ])
      expect(zones.fetch('.')).to eq([
        {'fqdn' => 'a.example.net', 'type' => 'A', 'rr' => ['127.0.0.4']},
      ])
    end
  end

  describe "#check!" do
    subject(:check) { dns.check! }

    context "with records with CNAME and other RR types" do
      before do
        dns.cname('a.example.com', 'x.example.com')
        dns.forward('a.example.com', :A, '127.0.0.1')
      end

      specify { expect { check }.to raise_error(DnsData::InvalidData) }
    end

    context "with multiple CNAME RR" do
      before do
        dns.cname('a.example.com', 'x.example.com')
        dns.cname('a.example.com', 'y.example.com')
      end

      specify { expect { check }.to raise_error(DnsData::InvalidData) }
    end

    context "with looped CNAME" do
      before do
        dns.cname('a.example.com', 'x.example.com')
        dns.cname('x.example.com', 'a.example.com')
      end

      specify { expect { check }.to raise_error(DnsData::InvalidData) }
    end

    context "with unresolvable CNAME" do
      before do
        dns.cname('a.example.com', 'x.example.com')
      end

      specify { expect { check }.to raise_error(DnsData::InvalidData) }
    end

    context "with valid zone data" do
      before do
        dns.forward('a.example.com', :A, '127.0.0.1')
        dns.reverse('127.0.0.1', 'a.example.com')
        dns.cname('cname.example.com', 'a.example.com')

        dns.forward('a.example.org', :A, '127.0.0.3')
        dns.forward('a.example.org', :A, '127.0.0.2')
        dns.reverse('127.0.0.2', 'a.example.org')

        dns.forward('a.example.net', :A, '127.0.0.4')
      end

      specify { expect { check }.not_to raise_error }
    end
  end
end
