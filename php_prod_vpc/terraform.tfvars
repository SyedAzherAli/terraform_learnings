//replace with your key pair name 
key_pair_name= "EC2keyPair"
//copy the ssh public key to working directory (where main.tf is present), and replace with your keypair file name
key_pair_source = "EC2keyPair.pem"
key_pair_destination = "/home/ec2-user/EC2keyPair.pem"