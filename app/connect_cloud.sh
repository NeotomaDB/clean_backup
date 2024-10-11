StatusURL()
{
  URL=$(aws ec2 describe-instances --instance-ids $INSTANCE --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
  echo $URL
}

echo Tunneling through ${URL}
URL=$(StatusURL)
echo Use localhost:5454 as the host/port connection for the database.
ssh -i ~/.ssh/NeotomaDBConnect.pem -o "StrictHostKeyChecking=no" -M -S ~/.ssh/awsprivatesocket -4 -f -N -L 5454:neotomaprivate.cxkwxkjpj8zi.us-east-2.rds.amazonaws.com:5432 ec2-user@$URL
