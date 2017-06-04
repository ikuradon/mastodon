namespace :comm do
    desc "Write git revision data."
    task :revwrite do
        revision = `git show -s --format=%H`.chomp()
        build = `git rev-list HEAD --count`.chomp()
        text = "-build.#{build}+g#{revision.slice(0..6)}"
        verfile = Rails.root.join('REVISION')
        verfile.write(text) if verfile.writable?
    end
end
