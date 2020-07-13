require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

get "/" do
  redirect "/lists" # so home page "/" will just take user to the "/lists" listing, what we want, https://launchschool.com/lessons/9230c94c/assignments/7bdd9818
end

get "/lists" do
  @lists = [{name: "Lunch Groceries", todos: []},  # each individual list will be a hash with a name key-value pair hash, and nested items hash with key value pairs
            {name: "Dinner Groceries", todos: []}
          ]
  erb :lists, layout: :layout # added a lists file, https://launchschool.com/lessons/9230c94c/assignments/7bdd9818
end