require 'rubygems'
require 'pdf/writer'      
require 'pdfwriter_extensions'
require 'labels'
require 'salva'

class UserReportPdfTransformer
  include Salva
  include Labels
  SIZES = [18, 16, 14, 12, 12, 12]

  def as_pdf(data)
    pdf =  PDF::Writer.new  	  
    pdf.select_font "Times-Roman"

    pdf.text("Informe de Actividades 2007", :font_size => SIZES[0], :justification => :center)
    myinstitution =  get_conf('institution')
    pdf.move_pointer(4)
    pdf.text(myinstitution, :font_size => SIZES[1], :justification => :center)

    pdf.text("\n\n")

    data.each do |hash|
      pdf.text(get_label(hash[:title])+"\n", :font_size => SIZES[hash[:level]]) if hash.has_key?(:title)
      pdf.move_pointer(10)
      if hash.has_key?(:data)
        paragraph_data(pdf, hash[:data])
        pdf.move_pointer(5)
      end
    end
    pdf.render
  end

  def paragraph_data(pdf, data)
    width = 198.324
    
    num = 1
    data.each do |text| 
      if text.is_a?Array
        if !text[1].nil? and !text[1].blank?
          label = '<b>'+get_label(text[0])+': </b>' 
          mywidth = pdf.text_line_width(label) > width ? pdf.text_line_width(label) : width
          y = pdf.y
          pdf.text(label, :font_size => SIZES[5])
          pdf.y = y
          pdf.text(text[1].to_s, :font_size => SIZES[5], :left => mywidth) 
        end
      else
        y = pdf.y
        pdf.text(num.to_s + '. ', :font_size => SIZES[5])  
        item_width = pdf.text_line_width(num.to_s + '. ')
        pdf.y = y       
        pdf.text(text, :font_size => SIZES[5], :justification => :full, :left => item_width) 
        num += 1
      end
      pdf.move_pointer(2)
    end
  end
  
end