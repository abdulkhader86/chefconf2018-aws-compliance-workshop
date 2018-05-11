class ChefConfWorkshop
  require 'net/http'
  require 'uri'
  require 'openssl'
  require 'json'

  def initialize(url, auth_token)
    @url = url
    @auth_token = auth_token
  end

  def make_request(endpoint, method, payload = nil)
    uri = URI.parse("#{@url}/#{endpoint}")

    if method == :post
      request = Net::HTTP::Post.new(uri)
      request['Api-Token'] = @auth_token
      request.content_type = 'application/json'
      request.body = JSON.dump(payload)
    else
      request = Net::HTTP::Get.new(uri)
      request['Api-Token'] = @auth_token
      request.content_type = 'application/json'
    end

    req_options = {
      use_ssl: uri.scheme == "https",
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
    }

    Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  end

  def user_id(email)
    user_id = JSON.parse(
      make_request("/api/v0/auth/users/#{email}", :get).body
    )['id']
  end

  def team_id(name)
    teams = JSON.parse(make_request('/api/v0/auth/teams', :get).body)['teams']
    teams.select { |x| x['name'] == name }.first['id']
  end

  def add_team(email, team_name)
    team_id = team_id(team_name)
    payload = {
      user_ids: [user_id(email)]
    }

    make_request("/api/v0/auth/teams/#{team_id}/users", :post, payload)
  end

  def create_user(user_details)
    user = {
      email: user_details[:email],
      name:  user_details[:name],
      password: user_details[:password],
      team: user_details[:team]
    }
    puts make_request("/api/v0/auth/users", :post, user).body
    puts add_team(user[:email], user[:team]).body if user[:team]
  end
end

helper = ChefConfWorkshop.new(ARGV[0], ARGV[1])

users = %w{${users}}

users.each do |user|
  helper.create_user(name: "#{user}", email: "#{user}", password: "${user_password}", team: 'admins')
end
