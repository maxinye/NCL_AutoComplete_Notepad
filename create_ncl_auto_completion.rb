#!/usr/bin/env ruby -wU
# This script was created for the purpose of generating the NCL auto-completion file of the "Notepad++" software, the source codes were based on Li Dong's script which can be found and downloaded from the website (https://github.com/dongli/sublime-ncl).

if File.exist? 'NCL.xml'
  print "[Warning]: NCL.xml exists, delete it!\n\n"
  File.delete 'NCL.xml'
end

completion_file = File.new 'NCL.xml', 'w+'
completion_file << "\<?xml version=\"1.0\" encoding=\"Windows-1252\" ?\>\n"
completion_file << "\<!--Update to NCL 6.3.0, 2015-5-21--\>\n"
completion_file << "\<!--Created by Xinye Ma\<worldwindmxy@gmail.com\>, Beijing, China.--\>\n"
completion_file << "\<NotepadPlus\>\n"
completion_file << "	\<AutoComplete\>\n"
completion_file << "		\<Environment ignoreCase=\"no\" startFunc=\"=\" stopFunc=\")\" paramSeparator=\",\" terminal=\"\<br\>\" additionalWordChar=\"\"\/\>\n"
completion_file << "		\<KeyWord name=\"load &quot;$NCARG_ROOT\/lib\/ncarg\/nclscripts\/csm\/gsn_code.ncl&quot; &quot;$NCARG_ROOT\/lib\/ncarg\/nclscripts\/csm\/gsn_csm.ncl&quot; &quot;$NCARG_ROOT\/lib\/ncarg\/nclscripts\/csm\/contributed.ncl&quot; &quot;$NCARG_ROOT\/lib\/ncarg\/nclscripts\/csm\/shea_util.ncl&quot; &quot;$NCARG_ROOT\/lib\/ncarg\/nclscripts\/wrf\/WRFUserARW.ncl&quot; &quot;$GEODIAG_UTILS\/geodiag_plot_utils.ncl&quot;\" \/\>\n"
completion_file << "		\<KeyWord name=\"begin\" \/\>\n"
completion_file << "		\<KeyWord name=\"end\" \/\>\n"
completion_file << "		\<KeyWord name=\"convert\" \/\>\n"

url_prefix = 'http://www.ncl.ucar.edu'

print "[1st step]: Generating NCL functions and parameters.\n"
print "[Notice]: Grabing function definitions from NCL website.\n\n"
page1 = `curl -s #{url_prefix}/Document/Functions/list_alpha.shtml`

categories = ['Functions/Built-in', 'Functions/Contributed', 'Functions/User_contributed', 'Functions/WRF_arw', 'Graphics/Interfaces']
categories.each do |category|
  page1.scan(/^\s*<a href="\/Document\/#{category}\/\w*\.shtml/).each do |x|
    func = x.match(/(\w+)(\.shtml)/)[1]
	if(func!="brunt_vaisala")then
    func_url = "#{url_prefix}#{x.match(/<a href="(.*)/)[1]}"
    page2 = `curl -s #{func_url}| iconv -f UTF-8 -t GBK`
    puts "[Notice]: Creating completion for #{func}."
    completion_file << "		\<KeyWord name=\"#{func}("
    begin
      prototype = page2.match(/(function|procedure) \w+ \(([^\)]*)\)$/m)[2].strip
	  #print "#{prototype}\n"
    rescue
      print page2.match(/(function|procedure) \w+ \(([^\)]*)\)$/m)
      print "[Error]: Failed to extract prototype for #{func}!"
      exit
    end
    i = 1
    prototype.each_line do |line|
	  arg = line.split(" ")[0].strip
	  if i > 1
	    completion_file << ",#{arg}"
	  else
	    completion_file << "#{arg}"
	  end
	  # If you want to generate the parameter types as well as the NCL functions, using the following codes!
      #arg = line.split("\n")[0].strip
	  #arg.split(' ').each do |word|
	    #completion_file << "#{word}"
	  #end
      i += 1
    end
    completion_file << ")\" \/\>\n"
	end
  end
end

print "[2nd step]: Generating NCL graphics resources.\n"
print "[Notice]: Grabing graphics resources from NCL website.\n\n"
page1 = `curl -s #{url_prefix}/Document/Graphics/Resources/list_alpha_res.shtml`

#debug_file = File.new 'debug.txt', 'w+'
resources = [] # There may be duplicate links in NCL graphics resources webpage.
codes = []
res = ""
res1 = ""
idefault = ""
ii = 0
numres = 0
status = 1
page1.each_line do |line|
  if status > 0
	line.scan(/^<a name="\w+"><\/a><strong>/).each do |x|
      res = x.match(/"(\w+)"></)[1]
      # Also remove the trailing '_*' stuff.
      res.gsub!(/_\w+/, '')
      if not resources.include? res
		resources << res
		numres += 1
		status = 0
		codes = []
		ii = 0
      end
	end
  end
  
  if status < 1
    line.scan(/<dt><code>\w+<\/code>/).each do |y|
	  code = y.match(/>(\w+)</)[1]
	  codes << code
	  ii += 1
    end
	
	line.scan(/Default:\s[  calculated as]*[<code>]*[&lt;]*"*-*\w*[.]*[@*+^sg]*[:B:$ZDV$:E:]*[<\/code>]*[&gt;]*\w*"*/).each do |z|
	  idefault = z.split("\n")[0].split(" ")[1]#.match(/[0@]?/)[1]
	  #debug_file << "#{idefault}\n"
	  status = 1
	  if ii > 0
		#completion_file << "		\<KeyWord name=\"#{res}=#{idefault}\" func=\"yes\"\>\n"
	    completion_file << "		\<KeyWord name=\"#{res}\" func=\"yes\"\>\n"
		completion_file << "				\<Overload retVal=\"\"\>\n"
		codes.each do |icode|
		    completion_file << "						\<Param name=\"#{icode}\" \/\>\n"
		end
		completion_file << "				\<\/Overload\>\n"
		completion_file << "		\<\/KeyWord\>\n"
		idefault = ""
	  else
		#completion_file << "		\<KeyWord name=\"#{res}=#{idefault}\" \/\>\n"
		completion_file << "		\<KeyWord name=\"#{res}\" \/\>\n"
		idefault = ""
	  end
	end
	
	line.scan(/^<a name="\w+"><\/a><strong>/).each do |u|
	  res1 = res
      res = u.match(/"(\w+)"></)[1]
      # Also remove the trailing '_*' stuff.
      res.gsub!(/_\w+/, '')
      if not resources.include? res
	  	#debug_file << "nodefault\n"
	    if ii > 0
		  completion_file << "		\<KeyWord name=\"#{res1}\" func=\"yes\"\>\n"
	      completion_file << "				\<Overload retVal=\"\"\>\n"
		  codes.each do |icode|
		    completion_file << "						\<Param name=\"#{icode}\" \/\>\n"
		  end
		  completion_file << "				\<\/Overload\>\n"
		  completion_file << "		\<\/KeyWord\>\n"
	    else
		  completion_file << "		\<KeyWord name=\"#{res1}\" \/\>\n"
	    end
		resources << res
		numres += 1
		status = 0
		codes = []
		ii = 0
      end
    end
  end
end
print "Total number of NCL resources: #{numres}\n"

print "[3rd step]: Generating NCL resource codes.\n"
print "[Notice]: Grabing resource codes from NCL website.\n\n"
page1 = `curl -s #{url_prefix}/Document/Graphics/Resources/list_alpha_res.shtml`

codes = []
page1.scan(/<code>\w+<\/code>/).each do |x|
  code = x.match(/>(\w+)</)[1]
  if not codes.include? code
	completion_file << "		\<KeyWord name=\"#{code}\" \/\>\n"
    codes << code
  end
end

print "[4th step]: Generating NCL color tables.\n"
print "[Notice]: Grabing color tables from NCL website.\n\n"
page1 = `curl -s #{url_prefix}/Document/Graphics/color_table_gallery.shtml`

color_tables = []
page1.scan(/^<td>\w+<br>$/).each do |x|
  color_table = x.match(/>(\w+)</)[1]
  if not color_tables.include? color_table
    completion_file << "		\<KeyWord name=\"#{color_table}\" \/\>\n"
    color_tables << color_table
  end
end

completion_file << "	\<\/AutoComplete\>\n"
completion_file << "\<\/NotepadPlus\>\n"
print "Congratulations! The task has been completed.\n"
