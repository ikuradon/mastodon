namespace :sidekiq do
    desc "Stop sidekiq safely."
    task :stop do
        processes = Sidekiq::ProcessSet.new
        abort 'Sidekiq process not running' if processes.count == 0

        processes.each do |process|
            process.quiet!
            puts "Send quiet signal to PID: #{process['pid']}"
        end

        puts 'Waiting 10 sec for status update...'
        sleep 10

        processes.each do |process|
            while (running_tasks = process['busy']) > 0
                puts "Waiting for tasks to finish. PID: #{process['pid']}, Num tasks: #{running_tasks}"
                sleep 5
            end

            process.stop!
            puts "Send stop signal to PID: #{process['pid']}"
        end
    end
end
