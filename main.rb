#! /usr/bin/env ruby
# -*- coding:utf-8 -*-
require 'sinatra'
#require "sinatra/reloader" if development?
require File.dirname(__FILE__)+'/filemodels'
require File.dirname(__FILE__)+'/globmodel'
USERNAME = 'user'
PASS = 'hoge'

### helper ##################
# need modify via environment 
helpers do
  def make_path(path)
    #  path.gsub('/var','/Volumes')
    path
  end
  
  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="filedb Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [USERNAME, PASS]
  end
  
end

### page ####################
get '/' do
  protected!
  @config = "sinatra"
  erb :index
end

get '/test' do
  protected!
  @config = "sinatra"
  "this is test"
end

##########  manage  ###########################################
get '/manage' do
  protected!
  ret = ["<h1>manage</h1>"]
  place_folder = "<li><a href='#href#' target='_blank'>#link#</a>"
  ret << place_folder.gsub("#href#","/filedb/manage/update_db").gsub("#link#",'update_db')
end

get '/manage/update_db' do
  protected!
  ret = ["<h1>DONE:filedb/manage/updatet_db</h1>"]
  ret = (ret + Filemodel.update_db).flatten
  ret.join("<li>")
end

##########  /manage  ###########################################

### API #####################

get '/api/dirs' do
  rets = Dirmodel.all.asc(:name)
  content_type  'application/json; charset=utf-8'    
  if rets.first.nil?
    [{:status => "ng"},[{}]].to_json
  else
    ret = []
    rets.each do |dir|
      pcount = dir.filemodels.count
      elem = {}
      elem[:_id] = dir.id;
      elem[:path] = dir.path;
      elem[:name] = "#{dir.name}(#{pcount})"
      ret << elem
    end
    [{:status => "ok"},ret].to_json
  end
end

get '/api/dir/:mid' do
  content_type  'application/json; charset=utf-8'    
  ret = Dirmodel.where(:_id => params['mid']).first
  files = ret.filemodels
  if files
    [{:status => "ok"},files].to_json
  else
    [{:status => "ng"},[{}]].to_json
  end
end

get '/api/search' do
  page = params['page'] ||= 1
  page = page.to_i
  per  = params['per'] ||= 10
  per = per.to_i
  
  filesret = Filemodel.search(params['qs'].gsub('<OR>','|'),page,per)
  content_type  'application/json; charset=utf-8'
  filesret.to_json
end

__END__

