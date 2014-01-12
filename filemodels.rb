#! /usr/bin/env ruby
# -*-coding:utf-8-*-
#require 'bson'
require 'mongo'
require 'mongoid'
require 'kconv'
require 'MeCab'
require 'digest/md5'

#Mongoid.load!( File.dirname(__FILE__) + "/mongoid.yml",:production)

Mongoid.configure do |config|
  config.master = Mongo::Connection.new('localhost').db('files-mongoid')
  # config.master = Mongo::Connection.new().db('photo-mongoid')
#  config.identity_map_enabled = true
end

class Dirmodel
  include Mongoid::Document
  field :path, type: String, :default => ''
  field :name, type: String, :default => ''
  field :created_at, :type => DateTime, :default => Time.now

#  index :path
  
  #  has_many :photomodels
  has_and_belongs_to_many :filemodels

  def models_count
    self.filemodels.size
  end
end

class Filemodel
  include Mongoid::Document
  field :path, type: String, :default => ''
  field :content ,type: String, :default => ''
  field :line, type: String, :default => ''
  field :name, type: String, :default => ''
  field :kind , type: String, :default => 'file'
  field :tag,:type => String ,:default => ''

  field :md5, type: String, :default => ''
  field :search, type: Array, :default => []
  field :update_at, :type => DateTime, :default => Time.now

#  index :md5
#  index :name
#  index :search
  
  has_and_belongs_to_many :dirmodels

  before_save :force_utf8
  before_save :update_search
  before_save :update_md5
  before_save :update_update_at
  before_save :model_debug

  def model_debug
    puts "model debug"
    p self
  end
  
  def force_utf8
    puts "FORCE_UTF("
    self.content = self.content.toutf8
    self.name = self.name.toutf8
  end
  
  def update_update_at
    puts "update_at"
    self.update_at = Time.now
  end

  def update_md5
    puts "update_md5"
    self.md5 = Digest::MD5.new.update(self.content).to_s.toutf8
  end
  
  def update_search
    puts "update_search"
    mecab = MeCab::Tagger.new("-Owakati")
    emit = mecab.parse("#{self.path} #{self.name} #{self.tag} #{self.content}".toutf8.downcase).split(' ').uniq
    self.search = emit
  end

  def update_tag(args)
    args[:string] = args[:string] ||= ''
    args[:mode] = args[:mode] ||= 'single'
   
    #string is tags string separated by space
    if args[:mode] == 'single'
      self.tag = args[:string]
      set_search
      self.save
      return
    end
    
    if args[:mode] == 'multi'
      tags = args[:string].split(' ')
      tags_orig = self.tag.split(' ')
      tags_ret = tags | tags_orig
      self.tag = tags_ret.join(' ')
      set_search
      self.save
      return 
    end
  end

  def self.search(query,page=1,per=10)
    page = page.to_i
    per = per.to_i
    per = 1 if per < 1
    page = 1 if page < 1
    skipnum=(page-1) * per

    if query == 'recent'
      Filemodel.recent(query,page,per)
    else    
      qs2 = query.gsub('<OR>','|').split('|').join(' ')
      keywords = MeCab::Tagger.new("-Owakati").parse(qs2).split(' ').map{|e| /^#{e.downcase}/}

      retcount = Filemodel.where(:search.all => keywords).size
      status = {:status => 'ok' ,:page => page,:total => retcount,:next => "no",:prev => "no",:qs => query}
      status[:next] = "yes" if retcount > page * per #TODO 境界微妙
      status[:prev] = "yes" if page > 1

      rets = Filemodel.where(:search.all => keywords)
        .skip(skipnum).limit(per)
      
      [status,rets]
    end
  rescue => ex
    puts ex
    [{:status => 'ng',:page => 0,:next => "no",:prev => "no"},[{}]]
  end

  def self.recent(query,page=1,per=10)
    page = page.to_i
    per = per.to_i
    per = 1 if per < 1
    page = 1 if page < 1
    skipnum=(page-1) * per
    
    retcount = Filemodel.all.size
    status = {:status => 'ok' ,:page => page,:total => retcount,:next => "no",:prev => "no",:qs => query}
    status[:next] = "yes" if retcount > page * per 
    status[:prev] = "yes" if page > 1

    rets = Filemodel.desc(:update_at)
      .skip(skipnum).limit(per)
    
    [status,rets]
  rescue => ex
    puts ex
    [{:status => 'ng',:page => 0,:next => "no",:prev => "no"},[{}]]
  end
  
  class << self
    def debug(a)
      require 'pp'
      pp a
    end
    
    def update_db
      
      delete_not_exist_entry

      require File.dirname(__FILE__)+'/globmodel'

      entries = GlobServerFiles.glob
      rets = []
      entries.each do |entry|
        begin
          if entry['kind'] == 'file'
            parsedobjs = parse_file(entry)
          end

          if entry['kind'] == 'orgfile'
            parsedobjs = parse_org(entry)
          end

          parsedobjs.each do |parsedobj|
            rets << chk_and_handle_file(parsedobj)
          end
        rescue =>ex
          p ex
        end  
      end
      rets.each do |e|
        debug("#########over######################")
        debug(e['filemodel'])
        puts; puts;
      end
      rets
    end

    def delete_not_exist_entry
      puts "#TODO delete_not_exist_entry:"
    end

    #notice this is array    
    def parse_file(entry)
      puts "parse_file:#{entry['path']}"
      entry['name'] = entry['path']
      buf = File.open(entry['path'],"r").read #TODO coding detection
      entry['content'] = buf
      entry['line'] = 1
      entry['tag'] = File.extname(entry['path']).gsub('.','')
      entry['parsed'] = true
      [entry]
    end

    
    #notice this is array    
    def parse_org(entry)
      puts "parse_org :#{entry['path']}"
      orgentries = []
      File.open(entry['path'],"r") do |io|
        tmp = []
        linenum = 1
        name = 'top'
        io.each do |line|
          if line =~ /^\*\*/
            orgentries << {
              'name' => "[org]#{name}",
              'line' => linenum ,
              'content' => tmp.join('')
            }
            tmp = []
            name = line
          end
          linenum += 1
          tmp << line
        end
      end
      orgentries.each do |orgentry|
        orgentry['parsed'] = true
        orgentry['tag'] = 'orgfile'
        orgentry['kind'] = entry['kind']
        orgentry['path'] = entry['path']
      end
      orgentries
    end

    def chk_and_handle_file(parsedobj)
      puts "chk_and_handle_file:#{parsedobj['path']}"
      parsedobj['checked'] = true
      md5 = Digest::MD5.new.update(parsedobj['content']).to_s;
      debug(parsedobj)
      debug(md5)
      debug('')
      dir = File.dirname(parsedobj['path']).to_s
      a_dir = Dirmodel.where(:path => dir).first
      if a_dir.nil?
        a_dir = Dirmodel.new(:path => dir,:name => dir)
        a_dir.save
      end
      detecta = Filemodel.where(:name => parsedobj['name'].to_s).first

      if detecta.nil?
        #new filemodel
        detecta = Filemodel.
          new(
              :path    => parsedobj['path'].to_s.toutf8,
              :content => parsedobj['content'].to_s.toutf8,
              :line    => parsedobj['line'].to_s.toutf8,
              :name    => parsedobj['name'].to_s.toutf8,
              :kind    => parsedobj['kind'].to_s.toutf8,
              :tag     => parsedobj['tag'].to_s.toutf8,
              )
        detecta.save
        a_dir.filemodels << detecta
        debug(detecta)
        a_dir.save
        parsedobj['filemodel'] = detecta
        parsedobj['dirmodel'] = a_dir
        return parsedobj
      end
      
      if detecta.md5 == md5
        puts "already exist and no change. or new => pass #{parsedobj['name']}"
        parsedobj['filemodel'] = detecta
        parsedobj['dirmodel'] = a_dir
        return parsedobj
      end

      # ==detecta.md5 != md5 ==
      detecta.content = parsedobj['content']
      detecta.line    = parsedobj['line']
      detecta.save

      parsedobj['filemodel'] = detecta
      parsedobj['dirmodel'] = a_dir
      return parsedobj
    end
  end
    
   
end
