<?php
$host = $_SERVER['HTTP_HOST'];
?>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <link rel="icon" href="http://ja.gravatar.com/userimage/14611836/d5caef2a5366cf647fc8fba3430e5854.png" type="image/png">
    <!--[if lt IE 9]>
    <script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->
    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"></script>    
    <title>俺俺&&google串刺し</title>
<style>
 *{margin:0;padding:0;}
 body{overflow-y:hidden;}
 #frame_l,#frame_r{width:50%;float:left;}
 header{ height:10%;}
 #main{ width:100%;height:90%;clear:both; }
 .iframe {width:100%;min-height:500px;height:100%;border:none;}
.f_text {
   background: none repeat scroll 0 0 lightgray;
   border-color: -moz-use-text-color -moz-use-text-color #FFF8E8;
   border-radius: 4px 4px 4px 4px;
   border-style: none none solid;
   border-width: medium medium 2px;
   box-shadow: 0 3px 3px #706751 inset;
   color: #453000;
   font-family: Helvetica,Arial,sans-serif;
   font-size: 24px;
   margin:8px;
   padding: 4px;
   float:left;
}
.button {
   background: darkgreen;
   border: 1px solid;
   border-radius: 4px 4px 4px 4px;
   box-shadow: 0 1px 1px darkgray inset, 0 1px 1px gray;
   color: #FFFFFF;
   cursor: pointer;
   display: block;
   font-family: Helvetica,Arial,sans-serif;
   font-size: 16px;
   font-weight: bold;
   padding: 6px 8px 5px 8px;
   margin:8px 25px 5px 5px;
   text-shadow: 0 -1px 1px #250300;
   float:left;
}

 
</style>
    <script>
function query(){
  var folder = "<iframe width=\"100%\" height=\"100%\" class=\"iframe\" seamless src=\"#{src}\" >";
  var query = $("#query").val();
  $("#frame_l").html(folder.replace("#{src}","https://<?php echo $host;?>/filedb/?qs=" + query));
  $("#frame_r").html(folder.replace("#{src}","http://www.google.co.jp/search?q=" + query));
  return false;
}
      
$(function(){
$("#b_query").click(function(){
        query();
        return false;
});
});
    </script>
    
  </head>
  <header>
    <h1 style="float:left;">俺俺&&google串刺し<h1>
    <form style="float:left;" onsubmit="query();return false;">
    <input type="text" class='f_text' id="query" name="query" value="" />
    <input type="submit" class='button' id="b_query" name="query" value="検索" />
    </form>
  </header>
  <div id="main" >
    <div id="frame_l">
      <iframe class="iframe" seamless src="https://<?php echo $host;?>/filedb/" name="frame_l" ></iframe>
    </div>
    <div id="frame_r">
      <iframe class="iframe" seamless src="http://google.co.jp" name="frame_r" ></iframe>
    </div>
  </div>
  
</body>
</html>
