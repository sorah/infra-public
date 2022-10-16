require_relative '../lib/dns_job'

RSpec.describe(DnsJob) do
  subject(:job) { DnsJob.new(hosts, addresses) }
  let(:hosts) { [] }
  let(:addresses) { [] }

  def double_host(name, primary_v4: nil, primary_v6: nil, public_v4: nil, public_v6: nil, interfaces: [], unmatched_primary_interface: false, unmatched_primary_public_interface: false)
    double(
      "host-#{name}",
      name: name,
      fqdn: "#{name}.fqdn.invalid",
      fqdn4: "#{name}.fqdn4.invalid",
      public_fqdn: "#{name}.public.invalid",
      public_fqdn4: "#{name}.public4.invalid",
      primary_v4: primary_v4,
      primary_v6: primary_v6,
      public_v4: public_v4,
      public_v6: public_v6,
      unmatched_primary_interface?: unmatched_primary_interface,
      unmatched_primary_public_interface?: unmatched_primary_public_interface,
      interface_data: interfaces.map { |_| [_.name, _] }.to_h,
    )
  end

  def double_interface(device_name, name, v4: [], v6: [], public_v4: [], public_v6: [])
    double(
      "iface-#{device_name}-#{name}",
      name: name,
      fqdn: "#{name}.#{device_name}.fqdn.invalid",
      fqdn4: "#{name}.#{device_name}.fqdn4.invalid",
      public_fqdn: "#{name}.#{device_name}.public.invalid",
      public_fqdn4: "#{name}.#{device_name}.public4.invalid",
      v4_addresses: v4,
      v6_addresses: v6,
      public_v4_addresses: public_v4,
      public_v6_addresses: public_v6,
    )
  end

  describe "#result" do
    subject(:result) { job.result }

    context "with simple hosts" do
      let(:hosts) do
        [
          double_host(
            'a',
            primary_v4: '127.0.0.1',
            primary_v6: 'fe80::0:a',
            public_v4: '100.100.0.1',
            public_v6: 'fe80::1:a',
            interfaces: [double_interface('a', 'eth0', v4: %w(127.0.0.1), v6: %w(fe80::0:a), public_v4: %w(100.100.0.1), public_v6: %w(fe80::1:a))],
          ),
        ]
      end

      it "generates host records" do
        expect(result.get('a.fqdn4.invalid', :A)).to eq(%w(127.0.0.1))
        expect(result.get('a.fqdn.invalid', :A)).to eq(%w(127.0.0.1))
        expect(result.get('a.fqdn.invalid', :AAAA)).to eq(%w(fe80::0:a))
      end

      it "generates iface records" do
        expect(result.get('eth0.a.fqdn.invalid', :CNAME)).to eq(%w(a.fqdn.invalid.))
        expect(result.get('eth0.a.fqdn4.invalid', :CNAME)).to eq(%w(a.fqdn4.invalid.))
      end

      it "generates public host records" do
        expect(result.get('a.public4.invalid', :A)).to eq(%w(100.100.0.1))
        expect(result.get('a.public.invalid', :A)).to eq(%w(100.100.0.1))
        expect(result.get('a.public.invalid', :AAAA)).to eq(%w(fe80::1:a))
      end

      it "generates public iface records" do
        expect(result.get('eth0.a.public.invalid', :CNAME)).to eq(%w(a.public.invalid.))
        expect(result.get('eth0.a.public4.invalid', :CNAME)).to eq(%w(a.public4.invalid.))
      end

      it "generates PTR records" do
        expect(result.get_reverse('127.0.0.1')).to eq(%w(a.fqdn.invalid.))
        expect(result.get_reverse('fe80::0:a')).to eq(%w(a.fqdn.invalid.))
        expect(result.get_reverse('100.100.0.1')).to eq(%w(a.public.invalid.))
        expect(result.get_reverse('fe80::1:a')).to eq(%w(a.public.invalid.))
      end
    end

    xcontext "with simple addresses" do
    end

    context "with hosts own multiple interfaces" do
      let(:hosts) do
        [
          double_host(
            'a',
            primary_v4: '127.0.0.1',
            primary_v6: 'fe80::0:a',
            public_v4: '100.100.0.1',
            public_v6: 'fe80::1:a',
            interfaces: [
              double_interface('a', 'eth0', v4: %w(127.0.0.1), v6: %w(fe80::0:a)),
              double_interface('a', 'eth1', public_v4: %w(100.100.0.1), public_v6: %w(fe80::1:a)),
              double_interface('a', 'eth2', v4: %w(127.0.0.2), v6: %w(fe80::0:b)),
              double_interface('a', 'eth3', public_v4: %w(100.100.0.2), public_v6: %w(fe80::1:b)),
            ],
          ),
        ]
      end

      it "generates host records" do
        expect(result.get('a.fqdn4.invalid', :A)).to eq(%w(127.0.0.1))
        expect(result.get('a.fqdn.invalid', :A)).to eq(%w(127.0.0.1))
        expect(result.get('a.fqdn.invalid', :AAAA)).to eq(%w(fe80::0:a))
      end

      it "generates iface records" do
        expect(result.get('eth0.a.fqdn.invalid', :CNAME)).to eq(%w(a.fqdn.invalid.))
        expect(result.get('eth0.a.fqdn4.invalid', :CNAME)).to eq(%w(a.fqdn4.invalid.))

        expect(result.get('eth2.a.fqdn4.invalid', :A)).to eq(%w(127.0.0.2))
        expect(result.get('eth2.a.fqdn.invalid', :A)).to eq(%w(127.0.0.2))
        expect(result.get('eth2.a.fqdn.invalid', :AAAA)).to eq(%w(fe80::0:b))
      end

      it "generates public host records" do
        expect(result.get('a.public4.invalid', :A)).to eq(%w(100.100.0.1))
        expect(result.get('a.public.invalid', :A)).to eq(%w(100.100.0.1))
        expect(result.get('a.public.invalid', :AAAA)).to eq(%w(fe80::1:a))
      end

      it "generates public iface records" do
        expect(result.get('eth1.a.public.invalid', :CNAME)).to eq(%w(a.public.invalid.))
        expect(result.get('eth1.a.public4.invalid', :CNAME)).to eq(%w(a.public4.invalid.))

        expect(result.get('eth3.a.public4.invalid', :A)).to eq(%w(100.100.0.2))
        expect(result.get('eth3.a.public.invalid', :A)).to eq(%w(100.100.0.2))
        expect(result.get('eth3.a.public.invalid', :AAAA)).to eq(%w(fe80::1:b))

        expect(result.get('eth1.a.fqdn.invalid', :CNAME)).to eq(%w(eth1.a.public.invalid.))
        expect(result.get('eth1.a.fqdn4.invalid', :CNAME)).to eq(%w(eth1.a.public4.invalid.))
        expect(result.get('eth3.a.fqdn.invalid', :CNAME)).to eq(%w(eth3.a.public.invalid.))
        expect(result.get('eth3.a.fqdn4.invalid', :CNAME)).to eq(%w(eth3.a.public4.invalid.))
      end

      it "generates PTR records" do
        expect(result.get_reverse('127.0.0.1')).to eq(%w(a.fqdn.invalid.))
        expect(result.get_reverse('fe80::0:a')).to eq(%w(a.fqdn.invalid.))
        expect(result.get_reverse('127.0.0.2')).to eq(%w(eth2.a.fqdn.invalid.))
        expect(result.get_reverse('fe80::0:b')).to eq(%w(eth2.a.fqdn.invalid.))
        expect(result.get_reverse('100.100.0.1')).to eq(%w(a.public.invalid.))
        expect(result.get_reverse('fe80::1:a')).to eq(%w(a.public.invalid.))
        expect(result.get_reverse('100.100.0.2')).to eq(%w(eth3.a.public.invalid.))
        expect(result.get_reverse('fe80::1:b')).to eq(%w(eth3.a.public.invalid.))

      end
    end

    context "with hosts own multiple addresses on its primary interface" do
      let(:hosts) do
        [
          double_host(
            'a',
            primary_v4: '127.0.0.1',
            primary_v6: 'fe80::0:a',
            public_v4: '100.100.0.1',
            public_v6: 'fe80::1:a',
            interfaces: [
              double_interface(
                'a', 'eth0',
                v4: %w(127.0.0.1 127.0.0.2),
                v6: %w(fe80::0:a fe80::0:b),
                public_v4: %w(100.100.0.1 100.100.0.2),
                public_v6: %w(fe80::1:a fe80::1:b),
              ),
            ],
          ),
        ]
      end

      it "generates host records" do
        expect(result.get('a.fqdn4.invalid', :A)).to eq(%w(127.0.0.1))
        expect(result.get('a.fqdn.invalid', :A)).to eq(%w(127.0.0.1))
        expect(result.get('a.fqdn.invalid', :AAAA)).to eq(%w(fe80::0:a))
      end

      it "generates iface records" do
        expect(result.get('eth0.a.fqdn4.invalid', :A)).to eq(%w(127.0.0.1 127.0.0.2))
        expect(result.get('eth0.a.fqdn.invalid', :A)).to eq(%w(127.0.0.1 127.0.0.2))
        expect(result.get('eth0.a.fqdn.invalid', :AAAA)).to eq(%w(fe80::0:a fe80::0:b))
      end

      it "generates public host records" do
        expect(result.get('a.public4.invalid', :A)).to eq(%w(100.100.0.1))
        expect(result.get('a.public.invalid', :A)).to eq(%w(100.100.0.1))
        expect(result.get('a.public.invalid', :AAAA)).to eq(%w(fe80::1:a))
      end

      it "generates public iface records" do
        expect(result.get('eth0.a.public4.invalid', :A)).to eq(%w(100.100.0.1 100.100.0.2))
        expect(result.get('eth0.a.public.invalid', :A)).to eq(%w(100.100.0.1 100.100.0.2))
        expect(result.get('eth0.a.public.invalid', :AAAA)).to eq(%w(fe80::1:a fe80::1:b))
      end

      it "generates PTR records" do
        expect(result.get_reverse('127.0.0.1')).to eq(%w(a.fqdn.invalid.))
        expect(result.get_reverse('fe80::0:a')).to eq(%w(a.fqdn.invalid.))
        expect(result.get_reverse('100.100.0.1')).to eq(%w(a.public.invalid.))
        expect(result.get_reverse('fe80::1:a')).to eq(%w(a.public.invalid.))

        expect(result.get_reverse('127.0.0.2')).to eq(%w(eth0.a.fqdn.invalid.))
        expect(result.get_reverse('fe80::0:b')).to eq(%w(eth0.a.fqdn.invalid.))
        expect(result.get_reverse('100.100.0.2')).to eq(%w(eth0.a.public.invalid.))
        expect(result.get_reverse('fe80::1:b')).to eq(%w(eth0.a.public.invalid.))
      end
    end

    context "with hosts use different primary interfaces for v4 and v6" do
      let(:hosts) do
        [
          double_host(
            'a',
            primary_v4: '127.0.0.1',
            primary_v6: 'fe80::0:a',
            public_v4: '100.100.0.1',
            public_v6: 'fe80::1:a',
            interfaces: [
              double_interface('a', 'eth0', v4: %w(127.0.0.1)),
              double_interface('a', 'eth1', public_v4: %w(100.100.0.1)),
              double_interface('a', 'eth2', v6: %w(fe80::0:a)),
              double_interface('a', 'eth3', public_v6: %w(fe80::1:a)),
            ],
          ),
        ]
      end

      it "generates host records" do
        expect(result.get('a.fqdn4.invalid', :A)).to eq(%w(127.0.0.1))
        expect(result.get('a.fqdn4.invalid', :AAAA)).to eq([])
        expect(result.get('a.fqdn.invalid', :A)).to eq(%w(127.0.0.1))
        expect(result.get('a.fqdn.invalid', :AAAA)).to eq(%w(fe80::0:a))
      end

      it "generates iface records" do
        expect(result.get('eth0.a.fqdn4.invalid', :A)).to eq(%w(127.0.0.1))
        expect(result.get('eth0.a.fqdn4.invalid', :AAAA)).to eq([])
        expect(result.get('eth0.a.fqdn.invalid', :A)).to eq(%w(127.0.0.1))
        expect(result.get('eth0.a.fqdn.invalid', :AAAA)).to eq([])
        expect(result.get('eth2.a.fqdn4.invalid', :A)).to eq([])
        expect(result.get('eth2.a.fqdn4.invalid', :AAAA)).to eq([])
        expect(result.get('eth2.a.fqdn.invalid', :A)).to eq([])
        expect(result.get('eth2.a.fqdn.invalid', :AAAA)).to eq(%w(fe80::0:a))

      end

      it "generates public host records" do
        expect(result.get('a.public4.invalid', :A)).to eq(%w(100.100.0.1))
        expect(result.get('a.public4.invalid', :AAAA)).to eq([])
        expect(result.get('a.public.invalid', :A)).to eq(%w(100.100.0.1))
        expect(result.get('a.public.invalid', :AAAA)).to eq(%w(fe80::1:a))
      end

      it "generates public iface records" do
        expect(result.get('eth1.a.public4.invalid', :A)).to eq(%w(100.100.0.1))
        expect(result.get('eth1.a.public4.invalid', :AAAA)).to eq([])
        expect(result.get('eth1.a.public.invalid', :A)).to eq(%w(100.100.0.1))
        expect(result.get('eth1.a.public.invalid', :AAAA)).to eq([])
        expect(result.get('eth3.a.public4.invalid', :A)).to eq([])
        expect(result.get('eth3.a.public4.invalid', :AAAA)).to eq([])
        expect(result.get('eth3.a.public.invalid', :A)).to eq([])
        expect(result.get('eth3.a.public.invalid', :AAAA)).to eq(%w(fe80::1:a))

        expect(result.get('eth1.a.fqdn.invalid', :CNAME)).to eq(%w(eth1.a.public.invalid.))
        expect(result.get('eth1.a.fqdn4.invalid', :CNAME)).to eq(%w(eth1.a.public4.invalid.))
        expect(result.get('eth3.a.fqdn.invalid', :CNAME)).to eq(%w(eth3.a.public.invalid.))
        expect(result.get('eth3.a.fqdn4.invalid', :CNAME)).to eq([])
      end

      it "generates PTR records" do
        expect(result.get_reverse('127.0.0.1')).to eq(%w(a.fqdn.invalid.))
        expect(result.get_reverse('fe80::0:a')).to eq(%w(a.fqdn.invalid.))
        expect(result.get_reverse('100.100.0.1')).to eq(%w(a.public.invalid.))
        expect(result.get_reverse('fe80::1:a')).to eq(%w(a.public.invalid.))
      end
    end

    context "with invalid data" do
      before do
        allow_any_instance_of(DnsData).to receive(:check!).and_raise(DnsData::InvalidData)
      end

      specify { expect { result }.to raise_error(DnsData::InvalidData) }
    end
  end
end
