require 'aws-sdk'
require 'net/dns'
require 'capistrano/dsl'

def elastic_load_balancer(dns_name, *args)

    include Capistrano::DSL

    aws_region= fetch(:aws_region, 'us-east-1')
    AWS.config(:access_key_id => fetch(:aws_access_key_id),
             :secret_access_key => fetch(:aws_secret_access_key),
             :ec2_endpoint => "ec2.#{aws_region}.amazonaws.com",
             :elb_endpoint => "elasticloadbalancing.#{aws_region}.amazonaws.com")

    load_balancer = AWS::ELB.new.load_balancers.find { |elb| elb.dns_name.downcase == dns_name.downcase }
    raise "EC2 Load Balancer not found for #{dns_name} in region #{aws_region}" if load_balancer.nil?

    load_balancer.instances.each do |instance|
        next if instance.status.to_s != 'running'
        hostname = if instance.vpc
            instance.private_ip_address
        else
            instance.dns_name || instance.private_ip_address
        end
        server(hostname, *args)
    end
end
