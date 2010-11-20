# encoding: UTF-8
module ProjectFilesHelper
  def file_type_image(ft)
    return  case ft.file_extension
    when 'doc' then  "document.png"
    when 'zip' then  "zip.png"
    when 'avi', 'mpeg','mpg' then  "video.png"
    when 'mov' then  "quicktime.png"
    when 'txt' then  "txt.png"
    when 'html' then  "html.png"
    when 'xml' then   "xml.png"
    when 'aiff', 'mp3', 'ogg', 'wav' then  "audio.png"
    when 'swf' then  "swf.png"
    when 'fla' then  "fla.png"
    when 'iso' then  "iso.png"
    when 'css' then  "css.png"
    when 'sql' then  "sql.png"
    when 'asf' then  "asf.png"
    when 'wvm' then  "wmv.png"
    when 'tgz' then  "tgz.png"
    when 'rar', 'zip','tar' then  "rar.png"
    when 'xls','sxc','csv' then "xls.png"

    else "unknown.png"
    end
  end
end

