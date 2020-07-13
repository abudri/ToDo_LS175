require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions # tells sinatra to activate it's session support
  set :sessions_secret, 'secret' # setting the session secret, to the string 'secret'
end

before do
  session[:lists] ||= [] # recall that  `session` is a hash, and for key :lists, the value is an array of lists, and each list itself is a hash  # to ensure we at least have an empty array if session[:lists] is non-existent, or nil, https://launchschool.com/lessons/9230c94c/assignments/2f3d171a
end

get "/" do
  redirect "/lists" # so home page "/" will just take user to the "/lists" listing, what we want, https://launchschool.com/lessons/9230c94c/assignments/7bdd9818
end

get "/lists" do
  @lists = session[:lists] # pull lists from session data
  erb :lists, layout: :layout # added a lists file, https://launchschool.com/lessons/9230c94c/assignments/7bdd9818
end

get "/lists/new" do
  session[:lists] << { name: "New List", todos: []} # a list is a hash that has two values, a name that is a string, and a todos key that is an array of todos / list items
  redirect "/lists"
end