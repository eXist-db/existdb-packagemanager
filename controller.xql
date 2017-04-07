xquery version "3.0";

declare namespace json="http://www.json.org";
declare namespace control="http://exist-db.org/apps/dashboard/controller";
declare namespace output="http://exquery.org/ns/rest/annotation/output";
declare namespace rest="http://exquery.org/ns/restxq";

import module namespace login-helper="http://exist-db.org/apps/dashboard/login-helper" at "modules/login-helper.xql";

import module namespace restxq="http://exist-db.org/xquery/restxq" at "modules/restxq.xql";
import module namespace packages="http://exist-db.org/apps/dashboard/packages/rest" at "modules/packages.xql";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $login := login-helper:get-login-method();

request:set-attribute("betterform.filter.ignoreResponseBody", "true"),
if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>
else if ($exist:path = "/") then
(: forward root path to index.xql :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>

else if (ends-with($exist:resource, "login.html")) then (
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
)
else if (ends-with($exist:resource, ".html")) then
    (: the html page is run through view.xql to expand templates :)
    try {
        let $loggedIn := $login("org.exist.login", (), true())
        let $user := request:get-attribute("org.exist.login.user")
        return
            if ($user and sm:is-dba($user)) then (
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    {$user}
                    <cache-control cache="yes"/>
                </dispatch>
            )
            else (
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <redirect url="login.html" />
                </dispatch>
            )
    } catch * {
        response:set-status-code(500),
        <response>
          <fail>{$err:description}</fail>
        </response>
    }

else if (matches($exist:path, ".xql/?$")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        { $login("org.exist.login", (), true()) }
        <set-attribute name="$exist:path" value="{$exist:path}"/>
    </dispatch>

else if (starts-with($exist:path, "/packages/")) then
    let $log := util:log("info", $exist:path)
    let $funcs := util:list-functions("http://exist-db.org/apps/dashboard/packages/rest")
    return (
      response:set-header("Cache-Control", "no-cache"),
      restxq:process($exist:path, $funcs)
    )
else
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
