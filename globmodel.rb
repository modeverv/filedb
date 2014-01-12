class GlobServerFiles
  def self.data(args = {})
    @folders = args[:folders] ||= [
                                   "/home/seijiro/Dropbox/code/ruby/memo/**/*rb",
                                   "/home/seijiro/Dropbox/code/ruby/ruby2011/**/*rb",
                                   "/home/seijiro/Dropbox/code/ruby/mydict/**/*",
                                   "/home/seijiro/Dropbox/code/scripts/**/*",
                                   "/home/seijiro/Dropbox/code/scheme/**/*",                      
                                   "/home/seijiro/Dropbox/code/python/**/*",                      
                                   "/home/seijiro/Dropbox/code/plsql/**/*",                      
                                   "/home/seijiro/Dropbox/code/php/memo**/*php",                      
                                   "/home/seijiro/Dropbox/code/php/memo**/*html",
                                   "/home/seijiro/Dropbox/code/memo**/*",
                                   "/home/seijiro/Dropbox/code/jshtml/memo**/*",                                                             ]
    @files = args[:files] ||= [
                               "/home/seijiro/Dropbox/code/howm/memo/ruby2011.org.txt",
                               "/home/seijiro/Dropbox/code/howm/memo/rails3study.org.txt",
                               "/home/seijiro/Dropbox/code/php/memo/cake_memo.org.txt",
                               "/home/seijiro/Dropbox/code/perl**/*",                      
                               "/home/seijiro/Dropbox/code/howm/memo/os.org.txt",
                               "/home/seijiro/Dropbox/code/howm/memo/jshtml.org.txt",
                              ]
    return [@folders,@files]    
  end

  def self.glob
    @entries = []
    @filders,@files = GlobServerFiles.data
    @folders.each do |p|
      Dir.glob("#{p}") do |element|
        puts "detect:#{element}"
        elem = {'path' => element,'kind' => 'file'}
        elem[:kind] = :orgfile if File.extname(element) =~ /\.org/
        @entries << elem
      end
    end
    @files = @files.map {|e| {'path' => e ,'kind' => 'orgfile'} }
    p @entries
    p @files
    return @entries + @files
  end
end
