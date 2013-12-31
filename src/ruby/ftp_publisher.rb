require 'net/ftp'
require 'optparse'
require 'rubygems'
require 'json'

hash_options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: your_app [options]"
  opts.on('-s [ARG]', '--sources_path [ARG]', "Specify the sources folder") do |v|
    hash_options[:s] = v
  end
  opts.on('-d [ARG]', '--destination_path [ARG]', "Specify the destination folder, if unspecified the source folder will be mirrored on server root") do |v=''|
    hash_options[:destination_path] = v
  end
  opts.on('-f [ARG]', '--ftp_config_file [ARG]', "Specify the path to the file containing the ftp server url and credentials") do |v|
    hash_options[:ftp_config_file] = v
  end
  opts.on('-r [ARG]', '--rules_path [ARG]',"") do |v|
    hash_options[:rules_path] = v
  end
  opts.on('--version', 'Display the version') do 
    puts "0.1"
    exit
  end
  opts.on('-h', '--help', 'Display this help') do 
    puts opts
    exit
  end
end.parse!

if hash_options[:s]==nil or !Dir::exist?(hash_options[:s])
	puts 'The specified source path is not valid or doesnt exists'
	puts "'" << hash_options[:s] << "'"
	exit
end
if hash_options[:destination_path] == nil
	hash_options[:destination_path] = '/'
end

ftp_configs = {}
if hash_options[:ftp_config_file] != nil 
	if !File::exist?(hash_options[:ftp_config_file])
		lines=File.open(hash_options[:ftp_config_file]).readlines
		ftp_configs[:host] = lines[0].gsub("\n","").gsub("\r","");
		ftp_configs[:user] = lines[1].gsub("\n","").gsub("\r","");
		ftp_configs[:pwd] = lines[2].gsub("\n","").gsub("\r","");
	else
		if !File::exist?(hash_options[:ftp_config_file])
			puts 'The specified ftp config file path is not valid'
			puts "'" << hash_options[:ftp_config_file] << "'"
			exit
		end
	end
end

@rules = {}
if hash_options[:rules_path] != nil and File::exist?(hash_options[:rules_path])
	@rules = JSON.parse(File.read(hash_options[:rules_path]))
end
@destination = hash_options[:destination_path]
@original_source = hash_options[:s]
def applyToTree(path, action, root=@original_source)
	Dir.foreach(path) do |f|
		next if f == '.' or f == '..'
		next_path = File.join(path, f)
		#puts next_path
		if(!@rules.empty? and @rules.has_key? next_path)
			if(@rules[next_path] == false)
				puts "Ignored file or path: "+ next_path
				next
			#else
		#		next_path = @rules[next_path]
		#		puts "Switched file or path for: "+ next_path
			end
		end
		if(File.directory?(next_path))
			applyToTree(next_path, action,root)
		else
			action.call(next_path, next_path.sub(root,"").sub(File.basename(next_path),""))
		end
	end
end

moveToFtp = Proc.new do |f,d|
	destination_path = @destination+d
	Net::FTP.open(ftp_configs[:host],ftp_configs[:user],ftp_configs[:pwd]) do |ftp|
		curr_folder = ""
		folders = destination_path.split("/")
		folders.each do |folder_name| 
			curr_folder += folder_name+'/'
			begin
				ftp.mkdir(curr_folder)
			rescue
				next
			end
		end
		#puts File.join(@destination+d,File.basename(f))
		ftp.put(f, File.join(@destination+d,File.basename(f)))
		ftp.close
	end
end

applyToTree(@original_source,moveToFtp)