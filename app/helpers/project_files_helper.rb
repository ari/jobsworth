module ProjectFilesHelper
  def file_type_image(ft)
    image = "unknown.png"
    case ft.file_type
    when ProjectFile::FILETYPE_DOC then image = "document.png"
    when ProjectFile::FILETYPE_ZIP then image = "zip.png"
    when ProjectFile::FILETYPE_AVI then image = "video.png"
    when ProjectFile::FILETYPE_MOV then image = "quicktime.png"
    when ProjectFile::FILETYPE_TXT then image = "txt.png"
    when ProjectFile::FILETYPE_HTML then image = "html.png"
    when ProjectFile::FILETYPE_XML then image = "xml.png"
    when ProjectFile::FILETYPE_AUDIO then image = "audio.png"
    when ProjectFile::FILETYPE_SWF then image = "swf.png"
    when ProjectFile::FILETYPE_FLA then image = "fla.png"
    when ProjectFile::FILETYPE_ISO then image = "iso.png"
    when ProjectFile::FILETYPE_CSS then image = "css.png"
    when ProjectFile::FILETYPE_SQL then image = "sql.png"
    when ProjectFile::FILETYPE_ASF then image = "asf.png"
    when ProjectFile::FILETYPE_WMV then image = "wmv.png"
    when ProjectFile::FILETYPE_TGZ then image = "tgz.png"
    when ProjectFile::FILETYPE_RAR then image = "rar.png"
    when ProjectFile::FILETYPE_XLS then image = "xls.png"
      
    else image = "unknown.png"
    end 

    image
  end 

end
