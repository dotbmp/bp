/*
 *  @Name:     test
 *  
 *  @Author:   Brendan Punsky
 *  @Email:    bpunsky@gmail.com
 *  @Creation: 31-03-2018 11:18:41 UTC-5
 *
 *  @Last By:   Brendan Punsky
 *  @Last Time: 01-04-2018 22:33:47 UTC-5
 *  
 *  @Description:
 *  
 */

import "core:fmt.odin"
import "core:os.odin"

import "html.odin"



oldtest :: proc() {
    doc := html.html();

    head := html.head(doc);
    body := html.body(doc);

    html.link(parent=head, rel="stylesheet", href="https://fonts.googleapis.com/css?family=Tangerine");

    html.style(head, `
        #content {
            width : 300px;
            margin : 20px;
            padding : 20px;
            background-color : aqua;

        }

        .fancy {
            font-family : 'Tangerine', cursive;
            font-size   : 60px;
            color       : white;
        }
    `);

    html.title(head, "hurlo wurld");

    content := html.div(parent=body, id="content");

    html.h1(parent=content, body="Hurlo, Wurld!", class="fancy");

    str := html.to_string(doc);

    fmt.println(str);

    os.write_entire_file("test.html", cast([]byte) str);
}



post :: proc(parent : ^html.Element, title, author, body : string) {
    post := html.div(parent=parent, class="post");
    
    html.h2(post, title);
    html.h4(post, author);
    html.hr(post);
    html.p(post, body);
}

test :: proc() {
    doc := html.document("html", "utf8", "Neat");

    head := html.find(doc, "head");
    body := html.find(doc, "body");

    html.meta(parent=head, name="viewport", content="width=device-width, initial-scale=1");

    html.style(head, `       
        html,body {
            background-color: white;
            font-family: "Times New Roman";
        }

        #title {
            margin-top: 0;
            margin-bottom: 0;
            color: black;
            font-size: 2em;
        }

        #posts {
            width: 49%;
            overflow: auto;
            float: left;
        }

        #table {
            float: right;
            width: 49%;
            outline-style: solid;
            outline-width: 1px;
            outline-color: black;
            margin: 5px 5px;
            padding: 2px 2px;
        }

        .post {
            outline-style: solid;
            outline-width: 1px;
            outline-color: black;
            margin: 5px 5px;
            padding: 2px 2px;
        }
    `);

    html.h1(parent=body, body="Neat", id="title");
    html.hr(body);

    posts := html.div(parent=body, id="posts");

    post(posts, "We want more", "by internetjerk321", "We want more posts!!");
    post(posts, "Here is more", "by niceguy2", "https://goodstuff.com/");
    post(posts, "Even more", "by randy", "https://catpics.net/");
    post(posts, "Even more", "by randy", "https://catpics.net/");
    post(posts, "Even more", "by randy", "https://catpics.net/");
    post(posts, "Even more", "by randy", "https://catpics.net/");

    table := html.div(parent=body, id="table");

    html.p(table, "Text!");

    
    str := html.to_string(doc);
    defer free(str);

    fmt.println(str);
    os.write_entire_file("test.html", cast([]byte) str);
}

main :: proc() {
    test();
}
