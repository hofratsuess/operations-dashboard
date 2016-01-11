require 'net/http'
require 'json'

uri = URI("https://api.github.com/user/repos?access_token=" + ENV["GIT_AUTH_TOKEN"])

SCHEDULER.every '30s', :first_in => 0 do
  Net::HTTP.get(uri)
  res = Net::HTTP.get_response(uri)
  repositories = JSON.parse(res.body)

  repos = Hash.new

  sendToWidget = Hash.new

  repositories.each{ |repo|
    repos["#{repo['id']}"] = { "name"=> "#{repo['name']}", "repoURI" => "https://api.github.com/repos/#{repo['full_name']}/milestones?access_token=" + ENV['GIT_AUTH_TOKEN'], "repoId" => "#{repo['id']}"}
  }

  repos.values.each{ |repo|
    milestones = Hash.new
    noMilestones = true
    repoURI = URI("#{repo['repoURI']}")
    Net::HTTP.get(repoURI)
    repoRes = Net::HTTP.get_response(repoURI)
    repository = JSON.parse(repoRes.body)

    repository.each{ |milestone|
      milestones["#{milestone['id']}"] = { title: "#{milestone['title']}", open: "#{milestone['open_issues']}", closed:"#{milestone['closed_issues']}"}
      noMilestones = false
    }
    if !noMilestones
      sendToWidget["#{repo['repoId']}"] = { title: "#{repo['name']}", milestones: milestones.values }
    end
    # repos["#{repo['id']}"] = { milestones: milestones }
  }

  puts sendToWidget

  send_event('git', { overall: "10", repos: sendToWidget.values})
end