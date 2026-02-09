namespace :admin do
  desc "Create or reset the admin user (prompts for credentials)"
  task setup: :environment do
    email = ENV.fetch("ADMIN_EMAIL") { print "Admin email: "; $stdin.gets.chomp }
    password = ENV.fetch("ADMIN_PASSWORD") { print "Admin password: "; $stdin.gets.chomp }

    user = User.find_or_initialize_by(email_address: email)
    user.password = password
    user.save!

    puts "Admin user #{user.email_address} #{user.previously_new_record? ? 'created' : 'updated'}."
  end
end
