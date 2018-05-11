KEYS=(public_keys/*.pub)

for i in "$${KEYS[@]}"; do
  USERNAME=$(basename $i | sed 's/.pub//')
  sudo chef-server-ctl user-create $USERNAME $USERNAME User $USERNAME@workshop.com ${user_password} > /dev/null
  sudo chef-server-ctl org-create $USERNAME $USERNAME Org -a $USERNAME > /dev/null
  sudo chef-server-ctl add-user-key $USERNAME --public-key_path $i --key_name terraform > /dev/null
done
