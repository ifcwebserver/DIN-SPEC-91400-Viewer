#! /usr/local/bin/ruby
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require '/var/www/html/conf.rb' 
require '/var/www/html/login.rb' 
$cgi = Console.session.cgi if Console.session.cgi != nil
$username = Console.session.username
puts $cgi.header("type"=> "text/html","X-Robots-Tag" =>"none")
puts "<html>\n<head><title>DIN SPEC 91400 -Viewer</title>"
puts "<meta charset='utf-8'/>"
puts "<link rel=\"stylesheet\" type=\"text/css\" href=\"../style.css\">"
puts "<script src=\"../js/prototype.js\" type=\"text/javascript\"></script>"
puts "<script type='text/javascript' src='../js/common.js'></script>"
puts "<script type='text/javascript' src='../js/css.js'></script>"
puts "<script type='text/javascript' src='../js/standardista-table-sorting.js'></script></head>"
puts "</head>\n<body>"
puts "<form  method='POST'>"
puts "DINSPEC91400 Datei (*.xml):"
HTML.select_box "file",[""] + Dir.glob("*.xml").join(",").split(","),[],false,""," style='width:200px'"
puts "<br> Zeige alle Eigenschaften<input type=checkbox name='show_all'><br>"
puts "<input id='mysubmit' type='submit' value='Zeigen'/>"
puts "</form><hr>"

def get_elements_list(el)
	elements_list = ""
	el.xpath("ElementRef").each do |e_ref|
		   elements_list +=  "<A NAME='#{e_ref.attribute("RefId").text}'><a href='index.rb?file=#{$file}&e_id=#{e_ref.attribute("RefId").text}##{e_ref.attribute("RefId").text}'>" + $elements[e_ref.attribute("RefId").text] + "</a></br>"
	if $e_id ==  e_ref.attribute("RefId").text or $show_all.to_s == "on"
		if $elements_properties[e_ref.attribute("RefId").text]
				elements_list += "<ul>" 
				$elements_properties[e_ref.attribute("RefId").text].each { |p|
				elements_list +=	"<li>" + $properties[p]  
					if $elements_properties_values[e_ref.attribute("RefId").text + "_" + p] != nil
						 $elements_properties_values[e_ref.attribute("RefId").text+ "_" + p].each { |pv|
							elements_list += "</br>--" + $values[pv]
						}
					end
				elements_list +=	"</li>"
					} 
				elements_list += "</ul>"
		end
	end
	end
	elements_list
end

$file=$cgi['file']
$e_id=$cgi['e_id']
$show_all=$cgi['show_all'] 

if $file
		doc = Nokogiri::XML(File.read($file))
		doc.remove_namespaces!
		HTML.h3 "DIN SPEC 91400"
		puts "<div style='width:80%;background-color:lightgray'>Version Info:" 
		HTML.h5 "Version Year:" + doc.xpath("/DINSPEC91400/@VersionYear").text
		HTML.h5 "Verion Month:" + doc.xpath("/DINSPEC91400/@VersionMonth").text
		puts "<hr>"
		puts "</div>"

		$elements={}
		$elements_properties={}
		$elements_properties_values={}
		doc.xpath("/DINSPEC91400/Elements/Element").each do |e|
			$elements[e.attribute("Id").text]= e.attribute("Caption").text
			e.xpath("PropertyRefs/PropertyRef").each { |p_id|
				$elements_properties[e.attribute("Id").text] = [] if $elements_properties[e.attribute("Id").text] == nil
				$elements_properties[e.attribute("Id").text] <<  p_id.attribute("RefId").text
				p_id.xpath("PropertyValueRefs/PropertyValueRef").each { |pv_ref|
					$elements_properties_values[e.attribute("Id").text + "_" + p_id.attribute("RefId").text] = [] if $elements_properties_values[e.attribute("Id").text + "_" + p_id.attribute("RefId").text] == nil
					$elements_properties_values[e.attribute("Id").text + "_" + p_id.attribute("RefId").text] << pv_ref.attribute("RefId").text
				}	
			}
		end
		$properties={}
		$properties_values={}
		$values={}
		doc.xpath("/DINSPEC91400/Properties/Property").each do |p|
			$properties[p.attribute("Id").text]= p.attribute("Caption").text
			p.xpath("PropertyValues/PropertyValue").each { |pv|
				$properties_values[p.attribute("Id").text] = [] if $properties_values[p.attribute("Id").text] == nil
				$properties_values[p.attribute("Id").text] <<  pv.attribute("Caption").text
				$values[pv.attribute("Id").text] = pv.attribute("Caption").text
			}
		end

		HTML.tableHeader "ID", "Caption", "Elements"
		id=1
		doc.xpath("/DINSPEC91400/Taxonomy/Node").each do |l1|
			HTML.arr_to_row [id,"<b>" + l1.attribute("Caption").text + "</b>" ,  get_elements_list(l1)] 
			id += 1
			l1.xpath("Node").each do |l2|
				HTML.arr_to_row [id,"__" + l2.attribute("Caption").text , get_elements_list(l2)]	
				id += 1
				l2.xpath("Node").each do |l3|
					HTML.arr_to_row [id,"____" + l3.attribute("Caption").text + "", get_elements_list(l3)] 
					id += 1
					l3.xpath("Node").each do |l4|
						HTML.arr_to_row [id,"______" + l4.attribute("Caption").text + "", get_elements_list(l4)]
						id += 1
						l4.xpath("Node").each do |l5|
							HTML.arr_to_row [id,"________" + l5.attribute("Caption").text + "", get_elements_list(l5)]
							id += 1
							l5.xpath("Node").each do |l6|
								HTML.arr_to_row [id,"__________" + l6.attribute("Caption").text + "", get_elements_list(l6)]
								id += 1
								l6.xpath("Node").each do |l7|
									HTML.arr_to_row [id,"____________" + l7.attribute("Caption").text + "", get_elements_list(l7)]
									id += 1
								end
							end			
						end
					end
				end
			end
		end
end

def print_elements(doc)
		#Elements
		HTML.h2  "Elements"
		HTML.tableHeader "ID", "Caption"
		id=1
		doc.xpath("/DINSPEC91400/Elements/Element").each do |e|
			 HTML.arr_to_row [id,"<b>" + e.attribute("Caption").text + "</b>"]
			 id+=1
		end
		puts "</table>"
end

def print_properties(doc)
		#Properties
		HTML.h2  "Properties"
		HTML.tableHeader "ID", "Caption","Type", "Property Values"
		id=1
		doc.xpath("/DINSPEC91400/Properties/Property").each do |e|
			property_values=""
			e.xpath("PropertyValues/PropertyValue").each { |pv| 
				property_values += pv.attribute("Caption").text + "</br>"
			}
			 HTML.arr_to_row [id, e.attribute("Caption").text,e.attribute("Type").text, property_values]
			 id+=1
		end
		puts "</table>"
 end
