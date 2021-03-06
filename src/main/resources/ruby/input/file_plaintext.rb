#Get logs from file(s) with single line
#@param : path - Path to logs directory
#@param : start_file_name - File logs will be start to read if no file specific,read oldest
#         or lastest file according to asc_by_fname
#@param : asc_by_fname - sort files in logs folder
#@param : start_pos -  the line number of log line will be start to read
#@return list_logs - a list of logs string
def getLogsByLine(path,start_file_name,start_pos,asc_by_fname)

  if(start_pos.nil?)
    start_pos = 1
  else
    if(start_pos.is_a?(String))
      begin
        start_pos = start_pos.to_i
      rescue Exception => ex
        puts "[Logstat]  : Incorrect parameters : 'start_pos' must be a number !"
        return
      end
    end
  end

  list_logs = Array.new
  if(asc_by_fname == nil)
    if(start_file_name == nil)
      puts "[Logstat]  : 'start_file_name' parameter must be required !"
      return
    end
    File.foreach(path+"/"+start_file_name).with_index do |line, line_num|

      if((line.strip != "") && (line_num >= start_pos ))
        list_logs << line
      end
    end
  else
    sorted_by_modified = Dir.entries(path).sort_by {|f| File.mtime(File.join(path,f))}.reject{|entry| entry == "." || entry == ".."}
    if(asc_by_fname == true)
      if(start_file_name == nil )
        start_file_name = sorted_by_modified.first
      end
      Dir.entries(path).sort.each  do |log_file|
        if((log_file <=> start_file_name) >= 0)
          if File.file?(File.join(path,log_file))
            File.foreach(File.join(path,log_file)).with_index do |line, line_num|
              if((log_file <=> start_file_name) == 0 )
                if((line.strip != "") && line_num >= start_pos)
                  list_logs << line
                end
              else
                if((line.strip != "") )
                  list_logs << line
                end
              end
            end
          end
        end
      end
    else
      if(start_file_name == nil )
        start_file_name = sorted_by_modified.last
      end
      Dir.entries(path).sort.reverse.each do |log_file|
        if File.file?(File.join(path,log_file))
          if((log_file <=> start_file_name) <= 0)
            File.foreach(File.join(path,log_file)).with_index do |line, line_num|
              if(( start_file_name <=> log_file) == 0)
                if((line.strip != "") && line_num <= start_pos)
                  list_logs << line
                end
              else
                if((line.strip != ""))
                  list_logs << line
                end
              end
            end
          end
        end
      end
    end
  end
  return list_logs
end

#Get logs from file(s) with multiline seperate by date
#@param : path - Path to logs directory
#@param : start_file_name - File logs will be start to read if no file specific,read oldest
#         or lastest file according to asc_by_fname
#@param : asc_by_fname - sort files in logs folder
#@param : from_date - the logs will be read from this time
#@return list_logs - a list of logs string
def getLogsByDate(path,start_file_name,from_date,asc_by_fname)
  require 'date'
  list_logs = Array.new
  if(asc_by_fname == nil)
    #Get logs from single file
    if(start_file_name == nil)
      puts "[Logstat]  : 'start_file_name' parameter must be required !"
      return
    end
    list_logs.push(*getLogsSingleFileByDate(path,start_file_name,from_date,asc_by_fname))
  else
    #Get logs from multi files
    sorted_by_modified = Dir.entries(path).sort_by {|f| File.mtime(File.join(path,f))}.reject{|entry| entry == "." || entry == ".."}
    if(asc_by_fname)
      #File sorted  ASC
      if(start_file_name == nil )
        start_file_name = sorted_by_modified.first
      end
      Dir.entries(path).sort.each  do |log_file|

        if File.file?(File.join(path,log_file))
          if((start_file_name <=> log_file) <= 0)
            list_logs.push(*getLogsSingleFileByDate(path,log_file,from_date,asc_by_fname))
          end
        end
      end
    else
      #File sorted DESC
      if(start_file_name == nil )
        start_file_name = sorted_by_modified.last
      end
      Dir.entries(path).sort.reverse.each do |log_file|
        if File.file?(File.join(path,log_file))
          if((start_file_name <=> log_file) >= 0)
            list_logs.push(*getLogsSingleFileByDate(path,log_file,from_date,asc_by_fname))
          end
        end
      end
    end
  end
  return list_logs
end

#Get logs from file with multiline seperate by date
#@param : path - Path to logs directory
#@param : start_file_name - File logs will be start to read if no file specific,read oldest
#         or lastest file according to asc_by_fname
#@param : asc_by_fname - sort files in logs folder
#@return list_logs - a list of logs in hashes
def getLogsSingleFileByDate(path,start_file_name,from_date,asc_by_fname)
  require 'date'
  logs_date = Date.new
  valid_items = false
  if(from_date != nil)
    begin
      from_date = Date.parse(from_date)
    rescue Exception => ex
      puts "[Logstat]  : Incorrect 'from_date' parameter: #{from_date}"
      return
    end
  end
  date_regex = /\A((\d{1,2}[-\/]\d{1,2}[-\/]\d{4})|(\d{4}[-\/]\d{1,2}[-\/]\d{1,2}))/
  list_logs = Array.new
  check_log_start = false
  log_items = ""
  File.foreach(path+"/"+start_file_name).with_index do |line, line_num|
    if ((line.strip != "") && (line =~ date_regex))
      str_date = line[date_regex,1]
      begin
        logs_date = Date.parse(str_date)
        if(from_date != nil)
          if(asc_by_fname == nil || asc_by_fname)
            if(from_date <= logs_date)
              check_log_start = true
              valid_items = true
            else
              if(valid_items)
                list_logs << log_items
              end
              valid_items = false
            end
          else
            if(from_date >= logs_date)
              check_log_start = true
              valid_items = true
            else
              if(valid_items)
                list_logs << log_items
              end
              valid_items = false
            end
          end
        else
          check_log_start = true
        end
      rescue Exception => e
        check_log_start = false
        puts "[Logstat]  :  #{e}"
      end
    else
      check_log_start = false
    end
    #Add log_items to list_logs
    if(check_log_start )
      if(log_items.strip != "")
        list_logs << log_items
      end
      #New logs items
      log_items = line
    else
      if(log_items.strip != "")
        log_items += line
      end
    end
  end
  #Last items
  if(valid_items == true )
    list_logs << log_items
  end
  return list_logs
end
