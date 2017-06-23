namespace :comm do
    desc "Write git revision data."
    task :revwrite do
        revision = `git show -s --format=%H upstream/master`.chomp()
        build = `git rev-list upstream/master --count`.chomp()
        text = "-build.#{build}+g#{revision.slice(0..6)}.with.comm_cx"
        verfile = Rails.root.join('REVISION')
        verfile.write(text) if verfile.writable?
    end
end
