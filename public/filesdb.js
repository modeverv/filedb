var AppUtil = {
    isMsIE : /*@cc_on!@*/false,
    debug : function(s){
//        console.log(s);
    },
    applyToSystem : function(){
        String.prototype.r = String.prototype.replace;
    }
};

// server
var server = {
    init : function(){
    },
    update_tag:function(id,tagstring){
        this._server_get('entry/updatetag/'+id,tagstring,page.emitexif);
    },
    search : function(qstring,p) {
        if(!p){p = 1;}
        this._server_get('search', qstring+"&page="+p+"&per=10",page.emitdir);
    },
    dirs : function(){
        this._server_get('dirs',"",page.emitdirs);
    },
    dir : function(id){
        this._server_get('dir/'+ id ,"",page.emitdir);
    },
    _server_get : function(uri,pdata,callback){
        $.ajax({  
                   type: "GET",
                   url: this._prefix + "/" + uri ,
                   data: "qs="+pdata,
                   success: function(msg){
                       callback(msg);
                   },
                   error:function(msg){
                       $("#grayout").fadeIn(0);
                   }
                   
               });    
    },
    _prefix : "/filedb/api"
};

if(config != "sinatra"){
}

var page = {
    /* manage selected */
    _selected_dirli_id : "",
    _selected_painli_id : "",
    chg_dirli_select : function(id){
        if(this._selected_dirli_id !== ""){
            $('#dirli-' + this._selected_dirli_id ).toggleClass('selected');
        }
        $('#dirli-' + id ).toggleClass('selected');
        this._selected_dirli_id = id;
    },
    chg_painli_select : function(id){
        if(this._selected_painli_id !== ""){
            $('#painli-' + this._selected_painli_id ).toggleClass('selected');
        }
        $('#painli-' + id ).toggleClass('selected');
        this._selected_painli_id = id;

    },
    /* make page */
    emitdirs : function(json){
        var status = json[0];
        json = json[1];

        // set window title and echo area
        if(page._selected_dirli_id === ""){
            $("#echoarea").html('');
        }

        // make page
        $("#side").html('');
        var elems = [];
        for(var i=0;i<json.length;i++){
            if( json[i]['name'] != 'Original' 
                && json[i]['name'] != 'Thumbnail' 
              ){
                  var elem = "<li id='dirli-" + json[i]['_id'] ;
                  elem+= "' onclick='reload_dir(\""+ json[i]['_id'] +"\");return false;'>";
                  //            for(x in json[i]){
                  //                elem += x + ":" + json[i][x] + "\n" ;
                  //            }
                  elem += json[i]['name'];
                  elem += "</li>";
                  elem = $(elem);
                  page._set_mover_css2elem(elem,'highlight');
                  elems.push(elem);
              }
        }
        var html = $("<ul></ul>");
        for(var i=0;i<elems.length;i++){
            html.append(elems[i]); 
        }
        $("#side").append(html);

        // ui
        if(page._selected_dirli_id !== ""){
            $('#dirli-' + page._selected_dirli_id ).toggleClass('selected');
        }
        $('#grayout').toggle();
    },
    emitdir : function(json){
        var status = json[0];
        json = json[1];

        // set window title and echo area
        if($('#query').val() !=''){
            var title = page.escapeHTML(":" + $('#query').val().split(' ').join('&'));
            if(!AppUtil.isMsIE)
                $('title').html(page.escapeHTML("filedb:" + $('#query').val().split(' ').join('&')));
        }else{
            var title = page.escapeHTML(":" + json[0]['path'].replace(/^.*\/(.*)\/.*$/,"$1") + "(" + json.length + ")" );
            if(!AppUtil.isMsIE)
                $('title').html(page.escapeHTML("filedb:" + json[0]['path'].replace(/^.*\/(.*)\/.*$/,"$1") + "(" + json.length + ")") );
        }

        $("#echoarea").html(title);

        // make page
        $("#pain").html('');

        var elems = [];
        for(var i=0;i<json.length;i++){
            // build html string
            var elem = "<li id='painli-" + json[i]['_id'] + "' ";
            elem += ">";
            var button = "<input type=\"button\" class=\"submit_button\" value=\"opencommand\" onclick=\"cp('#{path}','#{line}');\" style=\"float:right;\">".
                replace("#{path}",json[i]['path']).
                replace('#{line}',json[i]['line']);
            var entry_title = "<h3>#{title}</h3>".
                replace('#{title}' , page.escapeHTML( json[i].name ) ).
                replace('#{button}' , button );
//            var pre = "<pre> #{content} </pre>".
//                replace('#{content}', page.escapeHTML( json[i].content ) );
            var pre = "<pre>" + page.escapeHTML( json[i].content ) + "</pre>";
            elem += entry_title;
            elem += pre;
            elem += "</li>";
            elem = $(elem);
            page._set_mover_css2elem(elem,'highlight');
            page._set_click_event2elem(elem, json[i]['_id'],'painli-'+json[i]['_id'],json[i]['path'],json[i]['line'] );
            elems.push(elem);
        }
        var html = $("<ul>");
        for(var i=0;i<elems.length;i++){
            html.append(elems[i]); 
        }
        $("#pain").append(html);
        var pagina = "<div id='pagination'>";
        if(status.prev == "yes")
            pagina += "<span onclick='run(\"#{page}\");'>".replace(/\#\{page\}/g,status.page - 1) + "Prev</span>";
        if(status.prev == "yes" && status.next == "yes")
            pagina += " | ";
        if(status.next == "yes")
            pagina += "<span onclick='run(#{page})'>".replace(/\#\{page\}/g,status.page + 1) + "Next</span>";;
        pagina += "</div>";
        $("#pain").prepend(pagina);

        // ui
        $('#grayout').toggle();
    },
    /* private helper */
    _set_mover_css2elem : function(elem, cstr ) {
        elem.mouseover(function(){$(this).toggleClass(cstr);});
        elem.mouseout(function(){$(this).toggleClass(cstr);});
    },
    _opencommand : function (path,line){
        return "openemacs " + path + " " + line + "\n";
    },
    _set_click_event2elem : function(elem, id, elemid,path, line) {
        var m = page._opencommand(path,line);
        elem.find('h3').click(function(){
                       clip.setText(m);
                       $('footer').html( "<p>" + path + ":" + line + "</p><p>modeverv＠gmail.com</p>");
                       $(this).parent().toggleClass("selected");
                   });
        //        elem.click(function(){
        //           page.chg_painli_select(id);
        //        });

    },
    //htmlな文字をエスケープ
    escapeHTML : function(_strTarget){
        var div = document.createElement('div');
        var text =  document.createTextNode('');
        div.appendChild(text);
        text.data = _strTarget;
        return div.innerHTML.replace('<','&gt;').replace('>','&lt;');
    }
};


var qstringEscape = function(string){
    return string.replace("|",'<OR>');
};
var qstringUnEscape = function(string){
    return string.replace('%3COR%3E','|');
};
function updatetag(id){
    var tagvalue = $("#f_tag").val();
    server.update_tag(id,tagvalue);
}

// cp to clipboard
//
// do search
function run(p){
    if(!p){p = 1;}
    var qstring = $('#query').val();
    if(qstring != ""){
        $('#grayout').toggle();
        server.search(qstringEscape(qstring),p);
        stateHandle({kind:"qs",id:qstringEscape(qstring)},"?qs="+qstringEscape(qstring));
        page.chg_dirli_select("");
    }
    window.scroll(0,0);
    return false;
}

// reload dirs
function reload_dirs(){
    $('#grayout').toggle();
    server.dirs();
    return false;
}
// reload dir
function reload_dir(id){
    $('#grayout').toggle();
    $('#query').val('');
    $('#popup').fadeOut(0);
    page.chg_dirli_select(id);
    server.dir(id);
    stateHandle({kind:"dir",id:id},"?dir="+id);
    return false;
}

/* push state */
var stateDryRun = false;
function stateHandle(obj,path){
    if(!AppUtil.isMsIE){
        if(stateDryRun){
            stateDryRun = false;
        }else{
            history.pushState(obj,"",path);
        }
    }
}

function popStateHandler(e) {
    if(!AppUtil.isMsIE){
        // revive from state object
        if(e.state.kind=="qs"){
            stateDryRun = true;
            $('#query').val(e.state.id);
            run();
        }
        if(e.state.kind=="dir"){
            stateDryRun = true;
            page.chg_dirli_select(e.state.id);
            reload_dir(e.state.id);
        }
    }
}

function revive(location){
    if(location.search.match(/\?qs\=/)){
        // do search is need
        var qstring = decodeURI(location.search.replace('?qs=',''));

        $('#query').val(qstringUnEscape(qstring));

        $('#echoarea').html(qstringUnEscape(qstring));
        stateDryRun = true;
        run();
    }
    if(location.search.match(/^\?dir\=/)){
        // do load dir is need
        var dirstring = location.search.replace('?dir=','');
        stateDryRun = true;
        reload_dir(dirstring);
    }
}

// init
$(function(){
      revive(location);
  });

function my_complete_cp( client, text ) {
    $('footer').html("<p>copied:" + text + "</p><p>modeverv＠gmail.com");
    $('body').fadeOut(300).fadeIn(100);
}

var clip;
$(function(){
      if (window.history && window.history.pushState) {
          $(window).bind("popstate", function(e){
                             popStateHandler(e.originalEvent);
                         });
      }
      clip = new ZeroClipboard.Client(); 
      clip.setHandCursor( true );
      clip.setText(new Date());
      var h1 = $('header').find("h1").get(0);
      clip.glue(h1, h1);
      clip.addEventListener( 'onComplete', my_complete_cp );
  });


