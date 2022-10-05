include_cookbook 'nokogiri'
%w(
  aws-sdk-ec2
  aws-sdk-s3
  aws-sdk-sns
  aws-sdk-sqs
  aws-sdk-dynamodb
  aws-sdk-autoscaling
  aws-sdk-ssm
  aws-sdk-lambda
).each do |_|
  gem_package _
end
