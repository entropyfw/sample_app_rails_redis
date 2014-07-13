namespace :db do
  desc "Fill database with sample data"
  task populate: :environment do
    make_users
    make_microposts
    make_relationships
  end

  desc "Clean db objects"
  task clean_all: :environment do
    clean_all
  end
end

def make_users
  admin = User.create!(name: "admin",
                       email: "foo@foo.com",
                       password: "foobar",
                       password_confirmation: "foobar")
  admin.toggle!(:admin)
  1000.times do |n|
    name = Faker::Name.name
    email = "example-#{n+1}@bar.com"
    password = "password"
    User.create!(name: name, email: email, password: password,
                 password_confirmation: password)
  end
end

def make_microposts
  users = User.all
  1000.times do
    content = Faker::Lorem.sentence(5)
    users.each { |user| user.microposts.create!(content: content) }
  end
end

def make_relationships
  users = User.all
  user = users.first
  followed_users = users[1..500]
  followers      = users[3..350]
  followed_users.each { |followed| user.follow!(followed) }
  followers.each      { |follower| follower.follow!(user) }
end

def clean_all
  [User, Micropost, Relationship].each do |klass|
    klass.all.each(&:delete)
  end
end
