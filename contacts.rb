require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'psych'
require 'bcrypt'
require 'securerandom'
require 'awesome_print'

SAMPLE_CONTACTS = [
  { name: 'Bob', email: 'bob@abc.com', phone: '(000) 000-0000' },
  { name: 'Fred', email: 'fred@abc.com', phone: '(111) 111-1111' },
  { name: 'Larry', email: 'larry@abc.com', phone: '(222) 222-2222' }
]

configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
end

def find_contact_by_name(name)
  session[:contacts].find { |contact| contact[:name] == name }
end

def invalid_name?(name)
  name.to_s.strip.empty? || name !~ /\A[\w ]+\z/i
end

def invalid_email?(email)
  email.to_s !~ /\A\w+@\w+.[a-z]+\z/i
end

def invalid_phone?(phone)
  phone.to_s !~ /\A[-\(\)\d]\z/ && phone.delete('^0-9').size != 10
end

def status_422_error(msg, template)
  status 422
  session[:msg] = msg
  erb template
end

def update_contact(contact, name, phone, email)
  contact[:name] = name.strip.squeeze(' ')
  contact[:phone] = format_phone(phone)
  contact[:email] = email
end

def format_phone(phone)
  phone.delete('^0-9').gsub(/(...)(...)(....)/, '(\1) \2-\3')
end

before do
  session[:contacts] ||= SAMPLE_CONTACTS
end

get '/' do
  redirect '/contacts'
end

get '/contacts' do
  @contacts = session[:contacts]
  erb :contacts
end

get '/contacts/new' do
  erb :new
end

post '/contacts/new' do
  name, phone, email = params.values_at(:name, :phone, :email)
  contact = find_contact_by_name(params[:name])
  if invalid_name?(name)
    status_422_error('Invalid name', :new)
  elsif invalid_email?(email)
    status_422_error('Invalid email', :new)
  elsif invalid_phone?(phone)
    status_422_error('Invalid phone number', :new)
  else
    contact = (session[:contacts] << {}).last
    update_contact(contact, name, phone, email)
    session[:msg] = 'Contact has been created'
    redirect '/'
  end
end

get '/contacts/:name' do
  @contact = find_contact_by_name(params[:name])
  erb :contact
end

get '/contacts/:name/edit' do
  @contact = find_contact_by_name(params[:name])
  erb :edit
end

post '/contacts/:name/edit' do
  new_name, phone, email = params.values_at(:new_name, :phone, :email)
  contact = find_contact_by_name(params[:name])
  if invalid_name?(new_name)
    status_422_error('Invalid name', :edit)
  elsif invalid_email?(email)
    status_422_error('Invalid email', :edit)
  elsif invalid_phone?(phone)
    status_422_error('Invalid phone number', :edit)
  else
    update_contact(contact, new_name, phone, email)
    session[:msg] = 'Contact has been updated'
    redirect '/'
  end
end

post '/contacts/:name/delete' do
  contact = find_contact_by_name(params[:name])
  session[:contacts].delete(contact)

  session[:msg] = 'Contact has been deleted'
  redirect '/contacts'
end
