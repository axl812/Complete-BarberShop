#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
require 'pony'

def is_barber_exists? db, name
	db.execute('select * from Barbers where name=?', [name]).length > 0
end

def seed_db db, barbers

	barbers.each do |barber|
		if !is_barber_exists? db, barber
			db.execute'insert into Barbers (name) values ( ? )', [barber]
		end
	end
end

def get_db
	db = SQLite3::Database.new 'barbershop.db'
	db.results_as_hash = true
	return db
end

before do
	db = get_db
	@barbers = db.execute 'select * from Barbers'
end

configure do
	# создание таблиц в БД
	db = get_db
	db.execute 'CREATE TABLE IF NOT EXISTS 
		"Users" 
		(
		`id`INTEGER PRIMARY KEY AUTOINCREMENT,
		`username` TEXT,
		`phone`TEXT,
		`datestamp`TEXT,
		`barber`TEXT,
		`color`TEXT
		)'

	db.execute'CREATE TABLE IF NOT EXISTS 
		"Barbers" 
		(
		`id`INTEGER PRIMARY KEY AUTOINCREMENT,
		`name` TEXT
		)'

	# массив для БД
	seed_db db, ['Jessie Pinckman','Walter White','Gus Fring','Mike Ehrmantraut']

	enable :sessions
end

def select hh
	hh.select {|key| params[key] == ""}.values.join(" ")
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Войти'
  end
end

get '/' do
	erb "Hello! <a href=\"https://github.com/bootstrap-ruby/sinatra-bootstrap\">Original</a> pattern has been modified for <a href=\"http://rubyschool.us/\">Ruby School!!!!!!!!!!!!!!1</a>"
end

get '/about' do
	erb :about
end

get '/contacts' do
	erb :contacts
end

post '/contacts' do

@mail = params[:mail]
@message_from_mail = params[:message_from_mail]


	# хеш
	hh = { 	:mail => ' email',
			:message_from_mail => 'Введите сообщение!' }

	@error = select hh

	if @error != ''
		return erb :contacts
	end

	@log_mails = File.open './public/contacts.txt', 'a'
	@log_mails.write "Почта: #{@mail},\n Сообщение: #{@message_from_mail}\n"
	@log_mails.close

	
 Pony.mail(
	:to => 'exampledie7@gmail.com',
	:subject => params[:mail] + " has contacted you",
  	:body => params[:message_from_mail],
  	:via => :smtp,
  	:via_options => { 
    :address              => 'smtp.gmail.com', 
    :port                 => '587', 
    :enable_starttls_auto => true, 
    :user_name            => 'exampledie7@gmail.com', 
    :password             => 'qwerty111222', 
    :authentication       => :plain, 
    :domain               => 'localhost.localdomain'
  })

	erb "Спасибо за обращение, мы ответим Вам на: #{@mail}"
end

get '/visit' do
	erb :visit
end

post '/visit' do
	@username = params[:username]
	@phone = params[:phone]
	@datetime = params[:datetime]
	@barber = params[:barber]
	@color = params[:color]

	# хеш
	hh = { 	:username => 'Введите имя',
			:phone => 'Введите телефон',
			:datetime => 'Введите дату и время'}

	@error = select hh

	if @error != ''
		return erb :visit
	end

	# запись в таблицы Users БД
	@db = get_db
	@db.execute("insert into
		Users (
		username, 
		phone, 
		datestamp, 
		barber, 
		color
		) 
		values ( ?, ?, ?, ?, ? )", [@username, @phone, @datetime, @barber, @color])

	@log_users = File.open './public/users.txt', 'a'
	@log_users.write "\n Кто: #{@username}, Телефон: #{@phone}, Когда: #{@datetime}, Барбер: #{@barber}, Цвет: #{@color} \n "
	@log_users.close

	erb "<h2>Спасибо, вы записались!</h2>"
end

get '/showusers' do
	db = get_db
	@results = db.execute 'select * from Users order by id desc'

	erb :showusers
end

get '/login/form' do
  erb :login_form
end

post '/login/form' do
  session[:identity] = params['username']
  session[:pass] = params['password']

  if session[:identity] == 'admin' && session[:pass] == '666'
  where_user_came_from = '/secure/place'
  redirect to where_user_came_from
 	
  elsif session[:identity] == 'admin' && session[:pass] == 'admin'
    @error = 'Haha, nice try! Access denied!'
    erb :login_form
 
  else
    @error = 'Access denied!'
    erb :login_form
  end
end

get '/secure/place' do
	send_file './public/users.txt'
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end