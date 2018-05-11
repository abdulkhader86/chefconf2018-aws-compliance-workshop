require 'json'
require 'erb'

# Variables from Terraform
automate_server_fqdn = "${automate_server_fqdn}"
admin_token = "${automate_token}"
participant_names = %w{${participant_names}}
participant_fqdns = %w{${participant_fqdns}}
workstation_password = '${workstation_password}'

participants_info = Hash[participant_names.zip(participant_fqdns)]
participants_info.each_pair do |name, workstation_fqdn|
  info_file_path = File.join('/usr/share/nginx/html', "#{name}.html")
  File.open(info_file_path, 'w') do |file|
    puts "Creating '#{info_file_path}'"
    file.write <<-EOF
<html>
  <head>
    <title>#{name}</title>
  </head>
  <body>
  <h1>#{name}</h1>
  <h2>SSH Login Command:</h2>
  <p>ssh #{name}@#{workstation_fqdn}</p>
  <p>Password: #{workstation_password}</p>
  </br>
  <h2>InSpec Login Command:</h2>
  <p>inspec compliance login https://#{automate_server_fqdn} --user #{name} --token #{admin_token} --insecure</p>
  </br>
  <h2>Knife Bootstrap Command:</h2>
  <p>knife bootstrap #{name}@localhost -N #{name}-workstation -r 'recipe[mycorp_ssh_hardening]' --ssh-password #{workstation_password} --sudo</p>
  </body>
</html>
EOF
  end
end

File.open('/usr/share/nginx/html/index.html', 'w') do |file|
  file.write <<-EOH
<html>
  <head>
    <title>Workshop Info</title>
  </head>
  <body>
  <h1>Workshop Info</h1>
  <h2>Automate Server URL:</h2>
  <p><a href="https://#{automate_server_fqdn}">https://#{automate_server_fqdn}</a></p>
  <p>If using Chrome type "thisisunsafe" to bypass SSL warning</p>
  <p>If using Firefox click "Advanced->Add Exception->Confirm Security Exception"</p>
  </br>
  <h2>Participant Info Links:</h2>
EOH

  participants_info.each_pair do |name, _|
    file.write <<-EOI
  <p><a href="#{name}">#{name}</a></p>
EOI
  end

  file.write <<-EOT
  </body>
</html>
EOT
end
