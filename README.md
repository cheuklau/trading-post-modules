# Trading Post Ops

This repo deploys the [Trading Post](https://github.com/cheuklau/trading-post) website.

## Infrastructure v1.0

Infrastructure v1.0 gets the initial version of the app ready for testing. Everything is running on a single server.

### Dependencies

- Packer

### Build instructions

- Register an elastic IP (EIP) on AWS
- Register AWS Route53 domain name `mtgtradingpost.com`
- A hosted zone is automatically created for `mtgtradingpost.com`
- Create a record set pointing `mtgtradingpost.com` to the EIP
- Use Packer to build the monolith Amazon Machine Image (AMI):
```
cd v1/packer
packer build \
    -var 'aws_access_key=YOUR ACCESS KEY' \
    -var 'aws_secret_key=YOUR SECRET KEY' \
    packer.json
```
- Spin up an EC2 server with the created AMI
- Modify the Security Group to allow SSH/22 inbound from your IP and HTTP/80 inbound from you IP and all of the tester IPs
- Associate the EIP to the EC2 server
- SSH into the EC2 server using the EIP
- Start Apache server:
```
sudo a2ensite FlaskApp
sudo service apache2 restart
```

## Infrastructure v2.0

### To-Do

- Use AWS RDS for the backend
- Use an auto-scaling group (ASG) for the front-end
- Place an application load balancer (ALB) in front of the ASG
- Create a record set pointing `mtgtradingpost.com` to the ALB
- Automate creation of all infrastructure with Terraform

### Dependencies

- Packer
- Terraform