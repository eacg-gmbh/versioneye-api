# Organisation API

## Inventory

The inventory endpoint returns all components which are used as dependencies inside of the given organisation. The simplest request would look like this: 

```
https://www.versioneye.com/api/v2/organisations/ORGA_NAME/inventory?api_key=API_KEY
```

For example:

```
https://www.versioneye.com/api/v2/organisations/versioneye/inventory?language=Java&api_key=0123456789
```

The `ORGA_NAME` must fit to the used `API_KEY`. Please always use the `API_KEY` from the organisation you are using in your API request.

The response is a JSON object with this structure: 

```
{
  "LANGUAGE:PROD_KEY:NEWEST_VERSION": {
    "PROD_KEY::VERSION::LICENSE": [
      {"project_language": "", 
       "project_name": "",
        "project_id": "",
        "project_version": "",
        "project_teams: []}
    ]
  }
}
```

The first row identifies the component, for example `Ruby:rails:5.0.0`. The 2nd shows in which concrete version that component is used and which license it has in that concrete version. For example `rails:4.0.0:MIT`. The value of that key is an Array with the user projects which are using that component (`rails`) in that concrete version (`4.0.0`). Here a complete example: 

```
{
  "Ruby:rails:5.0.0": {
    "rails::4.0.0::MIT": [
      {"project_language": "Ruby", 
       "project_name": "My_first_ruby_project",
       "project_id": "123456789",
       "project_version": "",
       "project_teams: ['dev']}
    ]
  }
}
```

And here is an example for Java: 

```
{
  "Java:org.apache.maven/maven-plugin-api:3.3.9": {
    "org.apache.maven/maven-plugin-api::3.3.9::Apache-2.0": [
      {"project_language": "Java", 
       "project_name": "versioneye/versioneye_maven_plugin",
       "project_id": "123456789",
       "project_version": "3.10.2",
       "project_teams: ['dev']},
      {"project_language": "Java", 
       "project_name": "versioneye-maven-crawler",
       "project_id": "123456780",
       "project_version": "1.2.0",
       "project_teams: ['dev']}
    ],
    "org.apache.maven/maven-plugin-api::3.0.5::Apache-2.0": [
      {"project_language": "Java", 
       "project_name": "maven-indexer",
       "project_id": "12345670",
       "project_version": "1.1.3",
       "project_teams: ['dev']}
    ]
  },
  "Java:org.apache.maven/maven-core:3.3.9": {
    "org.apache.maven/maven-core::3.3.9::Apache-2.0": [
      {"project_language": "Java", 
       "project_name": "versioneye/versioneye_maven_plugin",
       "project_id": "12345671",
       "project_version": "3.10.2",
       "project_teams: ['dev']}
    ]
  }
}
```

In the example above we can see that the component `org.apache.maven/maven-plugin-api` is used by 3 projects in 2 different versions. The projects `versioneye/versioneye_maven_plugin` and `versioneye-maven-crawler` are using it in version 3.3.9. The `maven-indexer` project is using the same component in version 3.0.5.

The results can be filtered by: 

 - language 
 - team_name
 - project_version
 - post_filter
 
Here is an example: 

```
https://www.versioneye.com/api/v2/organisations/versioneye/inventory?language=Java&project_version=3.10.2&api_key=0123456789
```

In the same fashion it's possible to filer by team name.
