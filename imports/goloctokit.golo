module goloctokit

import Http
import JSON

import gololang.Errors

#  System.setProperty("log_goloctokit", "false")
local function logging = {
  return trying(-> System.getProperty("log_goloctokit"))
    : either(
      |res| -> res?: equals("true") orIfNull false,
      |err| -> false
    )
}

local function logging = |what| {
  if logging!() is true { println(what) }
}


----
# GitHubClient
----
struct gitHubClient = {
  baseUri, credentials
}

augment gitHubClient {
  # TODO: add headers
  function getHeaders = |this| -> [
    Http.header("Content-Type", "application/json"),
    Http.header("User-Agent", "GitHubGolo/1.0.0"),
    Http.header("Accept", "application/vnd.github.v3.full+json"),
    Http.header("Authorization", this: credentials())
  ]

  function getUri = |this, path| {
    return this: baseUri() + path
  }
  function getData = |this, path| {
    logging("LOG> getData: " + this: getUri(path))
    let resp = Http.request("GET", this: getUri(path), null, this: getHeaders())
    logging("LOG> getData > response: " + resp)
    return resp
  }

  function postData = |this, path, data| {
    logging("LOG> postData: " + this: getUri(path))
    let resp =  Http.request("POST", this: getUri(path), JSON.stringify(data), this: getHeaders())
    logging("LOG> postData > response: " + resp)
    return resp
  }

  function putData = |this, path, data| {
    logging("LOG> putData: " + this: getUri(path))
    let resp =  Http.request("PUT", this: getUri(path), JSON.stringify(data), this: getHeaders())
    logging("LOG> putData > response: " + resp)
    return resp
  }

  # TODO: deleteData
  ----
  The Zen of GitHub
  ----
  function octocat = |this| -> this: getData("/octocat"): data()

  ----
  # getUser
  ----
  function getUser = |this, user| -> JSON.toDynamicObjectTreeFromString(this: getData("/users/"+user): data())

  ----
  # getUsers
  {
  "total_count": 12,
  "incomplete_results": false,
  "items": [
    {
      "login": "mojombo",
      "id": 1,
      "avatar_url": "https://secure.gravatar.com/avatar/25c7c18223fb42a4c6ae1c8db6f50f9b?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-user-420.png",
      "gravatar_id": "",
      "url": "https://api.github.com/users/mojombo",
      "html_url": "https://github.com/mojombo",
      "followers_url": "https://api.github.com/users/mojombo/followers",
      "subscriptions_url": "https://api.github.com/users/mojombo/subscriptions",
      "organizations_url": "https://api.github.com/users/mojombo/orgs",
      "repos_url": "https://api.github.com/users/mojombo/repos",
      "received_events_url": "https://api.github.com/users/mojombo/received_events",
      "type": "User",
      "score": 105.47857
    }
  ]
}
  ----
  function searchUsers = |this, keyword| ->
    JSON.toDynamicObjectTreeFromString(
      this: getData("/search/users?q="+keyword): data()
    )

  function getRepositories = |this, user| {
    let repositoriesList = JSON.parse(this: getData("/users/"+user+"/repos"): data())
    return repositoriesList: reduce(
      list[],
      |repositories, repo| -> repositories: append(JSON.toDynamicObjectTree(repo))
    )
  }

  function getCommits = |this, owner, repository| {
    let commitsList = JSON.parse(this: getData("/repos/"+owner+"/"+repository+"/commits"): data())
    return commitsList: reduce(
      list[],
      |commits, commit| -> commits: append(JSON.toDynamicObjectTree(commit))
    )
  }

  ----
  # createRepository

  Create a new repository for the authenticated user.

      POST /user/repos

  Create a new repository in this organization. The authenticated user must be a member of the specified organization.

      POST /orgs/:org/repos

  TODO: create repository structure
  ----
  function createRepository = |this, name, description, private, hasIssues| {
    return JSON.toDynamicObjectTreeFromString(this: postData("/user/repos", map[
      ["name", name],
      ["description", description],
      ["private", private],
      ["has_issues", hasIssues],
      ["has_wiki", true],
      ["auto_init", true]
    ]): data())
  }

  function createRepository = |this, name, description, organization, private, hasIssues| {
    return JSON.toDynamicObjectTreeFromString(this: postData("/orgs/"+organization+"/repos", map[
      ["name", name],
      ["description", description],
      ["private", private],
      ["has_issues", hasIssues],
      ["has_wiki", true],
      ["auto_init", true]
    ]): data())
  }

  function createRepository = |this, name, description, organization, private, hasIssues, teamId| {
    return JSON.toDynamicObjectTreeFromString(this: postData("/orgs/"+organization+"/repos", map[
      ["name", name],
      ["description", description],
      ["private", private],
      ["has_issues", hasIssues],
      ["has_wiki", true],
      ["team_id", teamId],
      ["auto_init", true]
    ]): data())
  }


  ----
  # createIssue

  Any user with pull access to a repository can create an issue.

      POST /repos/:owner/:repo/issues

  TODO: create issue structure
  TODO: create issue with labels and milestone + assignees
  ----
  function createIssue = |this, title, body, owner, repository| {
    return JSON.toDynamicObjectTreeFromString(this: postData("/repos/"+owner+"/"+repository+"/issues", map[
      ["title", title],
      ["body", body]
    ]): data())
  }

  function createIssue = |this, title, body, labels, owner, repository| {
    return JSON.toDynamicObjectTreeFromString(this: postData("/repos/"+owner+"/"+repository+"/issues", map[
      ["title", title],
      ["body", body],
      ["labels", labels]
    ]): data())
  }

  ----
      title	string	Required. The title of the issue.
      body	string	The contents of the issue.
      milestone	integer	The number of the milestone to associate this issue with. NOTE: Only users with push access can set the milestone for new issues. The milestone is silently dropped otherwise.
      labels	array of strings	Labels to associate with this issue. NOTE: Only users with push access can set labels for new issues. Labels are silently dropped otherwise.
      assignees	array of strings	Logins for Users to assign to this issue. NOTE: Only users with push access can set assignees for new issues. Assignees are silently dropped otherwise.
  ----
  function createIssue = |this, title, body, labels, milestone, assignees, owner, repository| {
    return JSON.toDynamicObjectTreeFromString(this: postData("/repos/"+owner+"/"+repository+"/issues", map[
      ["title", title],
      ["body", body],
      ["milestone", milestone],
      ["labels", labels],
      ["assignees", assignees]
    ]): data())
  }
  function createIssue = |this, title, body, labels, milestone, owner, repository| {
    return JSON.toDynamicObjectTreeFromString(this: postData("/repos/"+owner+"/"+repository+"/issues", map[
      ["title", title],
      ["body", body],
      ["milestone", milestone],
      ["labels", labels]
    ]): data())
  }
  ----
  Add assignees to an Issue

  This call adds the users passed in the assignees key (as their logins) to the issue.

      POST /repos/:owner/:repo/issues/:number/assignees

  Sample: TODO: test with 2.7 version

      gitHubClientEnterprise: addAssignees(
        issueNumber= issue: number(),
        assignees=["babs", "buster"],
        owner="k33g",
        repository="my-little-demo"
      )

  ----
  function addAssignees = |this, issueNumber, assignees, owner, repository| {
    return JSON.toDynamicObjectTreeFromString(this: postData("/repos/"+owner+"/"+repository+"/issues/"+issueNumber+"/assignees", map[
      ["assignees", assignees]
    ]): data())
  }

  ----
  Add comment to an issue
  POST /repos/:owner/:repo/issues/:number/comments

  ----
  function addCommentToIssue = |this, issueNumber, body, owner, repository| {
    return JSON.toDynamicObjectTreeFromString(this: postData("/repos/"+owner+"/"+repository+"/issues/"+issueNumber+"/comments", map[
      ["body", body]
    ]): data())
  }


  ----
  # createLabel

      POST /repos/:owner/:repo/labels

  ## Parameters

  - name	string	Required. The name of the label.
  - color	string	Required. A 6 character hex code, without the leading #, identifying the color.

  ----
  function createLabel = |this, name, color, owner, repository| {
    return JSON.toDynamicObjectTreeFromString(this: postData("/repos/"+owner+"/"+repository+"/labels", map[
      ["name", name],
      ["color", color]
    ]): data())
  }

  function createLabel = |this, label, owner, repository| { # label is a DynamicObject
    return JSON.toDynamicObjectTreeFromString(this: postData("/repos/"+owner+"/"+repository+"/labels", map[
      ["name", label: name()],
      ["color", label: color()]
    ]): data())
  }

  function createLabels = |this, labels, owner, repository| {
    let labelsList = list[]
    labels: each(|label| { # label is a DynamicObject
      labelsList: append(this: createLabel(label, owner, repository))
    })
    return labelsList
  }

  ----
  # getLabels

  List all labels for this repository

    GET /repos/:owner/:repo/labels

  ----
  function getLabels = |this, owner, repository| {
    let labelsList = JSON.parse(this: getData("/repos/"+owner+"/"+repository+"/labels"): data())
    return labelsList: reduce(
      list[],
      |labels, label| -> labels: append(JSON.toDynamicObjectTree(label))
    )
  }

  ----
  Add labels to an issue

      POST /repos/:owner/:repo/issues/:number/labels

  Input

      [
        "Label1",
        "Label2"
      ]
  ----
  function addLabelsToIssue = |this, issueNumber, labels, owner, repository| {
    # TODO
  }


  ----
  Create a milestone

      POST /repos/:owner/:repo/milestones

  - title	string	Required. The title of the milestone.
  - state	string	The state of the milestone. Either open or closed. Default: open
  - description	string	A description of the milestone.
  - TODO: due_on	string	The milestone due date. This is a timestamp in ISO 8601 format: YYYY-MM-DDTHH:MM:SSZ.

  ----
  function createMilestone = |this, title, state, description, owner, repository| {
    return JSON.toDynamicObjectTreeFromString(this: postData("/repos/"+owner+"/"+repository+"/milestones", map[
      ["title", title],
      ["state", state],
      ["description", description]
    ]): data())
  }

  function createMilestone = |this, title, state, description, owner, repository, due_on| {
    return JSON.toDynamicObjectTreeFromString(this: postData("/repos/"+owner+"/"+repository+"/milestones", map[
      ["title", title],
      ["state", state],
      ["description", description],
      ["due_on", due_on]
    ]): data())
  }

  function createMilestone = |this, milestone, owner, repository| { # milestone is a DynamicObject
    return JSON.toDynamicObjectTreeFromString(this: postData("/repos/"+owner+"/"+repository+"/milestones", map[
      ["title", milestone: title()],
      ["state", milestone: state()],
      ["description", milestone?: description()],
      ["due_on", milestone?: due_on()]
    ]): data())
  }

  function createMilestones = |this, milestones, owner, repository| {
    let milestonesList = list[]
    milestones: each(|milestone| { # milestone is a DynamicObject
      milestonesList: append(this: createMilestone(milestone, owner, repository))
    })
    return milestonesList
  }

  ----
  # getMilestones

  List all milestones for this repository

    GET /repos/:owner/:repo/milestones

  ----
  function getMilestones = |this, owner, repository| {
    let milestonesList = JSON.parse(this: getData("/repos/"+owner+"/"+repository+"/milestones"): data())
    return milestonesList: reduce(
      list[],
      |milestones, milestone| -> milestones: append(JSON.toDynamicObjectTree(milestone))
    )
  }

  ----
  Get a Reference

      GET /repos/:owner/:repo/git/refs/:ref

    The ref in the URL must be formatted as heads/branch, not just branch.
    For example, the call to get the data for a branch named skunkworkz/featureA would be:

      GET /repos/:owner/:repo/git/refs/heads/skunkworkz/featureA

  Return:
      {
        "ref": "refs/heads/featureA",
        "url": "https://api.github.com/repos/octocat/Hello-World/git/refs/heads/featureA",
        "object": {
          "type": "commit",
          "sha": "aa218f56b14c9653891f9e74264a383fa43fefbd",
          "url": "https://api.github.com/repos/octocat/Hello-World/git/commits/aa218f56b14c9653891f9e74264a383fa43fefbd"
        }
      }
  ----
  function getReference = |this, ref, owner, repository| {
    let resp = this: getData("/repos/"+owner+"/"+repository+"/git/refs/"+ref)
    return JSON.toDynamicObjectTreeFromString(resp: data())
  }

  ----
  Create a Reference

      POST /repos/:owner/:repo/git/refs

  Parameters
  - ref	type	Required. The name of the fully qualified reference (ie: refs/heads/master). If it doesn't start with 'refs' and have at least two slashes, it will be rejected.
  - sha	type	Required. The SHA1 value to set this reference to

  Input

      {
        "ref": "refs/heads/featureA",
        "sha": "aa218f56b14c9653891f9e74264a383fa43fefbd"
      }

      function createReference = |this, ref, sha, owner, repository| {
        return JSON.toDynamicObjectTreeFromString(this: postData("/repos/"+owner+"/"+repository+"/git/refs", map[
          ["ref", ref],
          ["sha", sha]
        ])?: data() orIfNull "{}")
      }

  TODO:
  - if branch already exists -> error stop then gololang.Error
  - postData -> @result or trying { and test response -> return Result.fail }
  ----
  function createReference = |this, ref, sha, owner, repository| {
    let resp = this: postData("/repos/"+owner+"/"+repository+"/git/refs", map[
      ["ref", ref],
      ["sha", sha]
    ])
    return JSON.toDynamicObjectTreeFromString(resp: data())
  }

  function createBranch = |this, name, from, owner, repository| {

    let sha = this: getReference(
      ref="heads/"+from,
      owner=owner,
      repository=repository
    ): object(): sha()

    return this: createReference(
      ref="refs/heads/"+name,
      sha=sha,
      owner=owner,
      repository=repository
    )
  }

  ----
  http://stackoverflow.com/questions/469695/decode-base64-data-in-java
  ----
  function toBase64 = |this, content| {
    let bytes = content: getBytes("UTF-8")
    return java.util.Base64.getEncoder(): encodeToString(bytes)
  }

  ----
  # createCommit

  ----
  function createCommit = |this, fileName, content, message, branch, owner, repository| {
    let resp = this: putData("/repos/"+owner+"/"+repository+"/contents/"+fileName, map[
      ["message", message],
      ["branch", branch],
      ["content", this: toBase64(content)]
    ])
    return JSON.toDynamicObjectTreeFromString(resp: data())
  }

  # WORK IN PROGRESS
  function fetchCommitBySHA = |this, sha, owner, repository| {
    let resp = this: getData("/repos/"+owner+"/"+repository+"/git/commits/"+sha)
    return JSON.toDynamicObjectTreeFromString(resp: data())
  }

  # Get a single commit
  # GET /repos/:owner/:repo/commits/:sha
  # https://developer.github.com/v3/repos/commits/#get-a-single-commit
  function fetchSingleCommit = |this, sha, owner, repository| {
    let resp = this: getData("/repos/"+owner+"/"+repository+"/commits/"+sha)
    return JSON.toDynamicObjectTreeFromString(resp: data())
  }

  function fetchContent = |this, path, owner, repository, decode| {
    let resp = this: getData("/repos/"+owner+"/"+repository+"/contents/"+path)
    let data = JSON.toDynamicObjectTreeFromString(resp: data())
    if decode is true {
      let decoder = java.util.Base64.getMimeDecoder()
      let bytesDecoded = decoder: decode(data: content(): getBytes())
      data: content(String(bytesDecoded))
    }
    return data    
  }

  ----
  # createPullRequest
  ----
  function createPullRequest = |this, title, body, head, base, owner, repository| {
    let resp = this: postData("/repos/"+owner+"/"+repository+"/pulls", map[
      ["title", title],
      ["body", body],
      ["head", head],
      ["base", base]
    ])
    return JSON.toDynamicObjectTreeFromString(resp: data())
  }

  ----
  # Organizations
  ----
  function createOrganization = |this, login, admin, profile_name| {
    let resp = this: postData("/admin/organizations", map[
      ["login", login],
      ["admin", admin],
      ["profile_name", profile_name]
    ])
    return JSON.toDynamicObjectTreeFromString(resp: data())
  }
  ----
  # Teams
  ----
  function createTeam = |this, org, name, description, repo_names, privacy, permission| {
    let resp = this: postData("/orgs/"+org+"/teams", map[
      ["name", name],
      ["description", description],
      ["repo_names", repo_names],
      ["privacy", privacy],
      ["permission", permission]
    ])
    return JSON.toDynamicObjectTreeFromString(resp: data())
  }
  function getTeams = |this, organization| {
    let organizationList = JSON.parse(this: getData("/orgs/"+organization+"/teams"): data())
    return organizationList: reduce(
      list[],
      |organizations, organization| -> organizations: append(JSON.toDynamicObjectTree(organization))
    )
  }
  function getTeamByName = |this, name, organization| {
    return this: getTeams(organization): find(|team| { return team: name(): equals(name) })
  }
  function getTeamById = |this, id, organization| {
    return JSON.toDynamicObjectTreeFromString(this: getData("/teams/"+id): data())
  }


  function updateTeamRepository = |this, id, organization, repository, permission| {
    let resp = this: putData("/teams/"+id+"/repos/"+organization+"/"+repository, map[
      ["permission", permission]
    ])
    if resp: data() isnt null {
      return JSON.toDynamicObjectTreeFromString(resp: data())
    } else {
      return null # always return `Status: 204 No Content`
    }
  }

  function addTeamMembership = |this, teamId, userName, role| {
    let resp = this: putData("/teams/"+teamId+"/memberships/"+userName, map[
      ["role", role]
    ])
    return JSON.toDynamicObjectTreeFromString(resp: data())
  }
  # admin or member
  function addOrganizationMembership = |this, org, userName, role| {
    let resp = this: putData("/orgs/"+org+"/memberships/"+userName, map[
      ["role", role]
    ])
    return JSON.toDynamicObjectTreeFromString(resp: data())
  }


  ----
  # Hooks
  ----
  function createHook = |this, owner, repository, hookName, hookConfig, hookEvents, active| {
    let config = hookConfig
    let events =  hookEvents
    let params = map[
      ["name", hookName],
      ["config",config ],
      ["events", events],
      ["active", active]
    ]

    let resp = this: postData("/repos/"+owner+"/"+repository+"/hooks", params)
    #return JSON.toDynamicObjectTreeFromString(resp: data())
    return resp
  }

  function createOrganizationHook = |this, org, hookName, hookConfig, hookEvents, active| {
    let config = hookConfig
    let events =  hookEvents
    let params = map[
      ["name", hookName],
      ["config",config ],
      ["events", events],
      ["active", active]
    ]
    #println("/orgs/"+org+"/hooks")
    let resp = this: postData("/orgs/"+org+"/hooks", params)
    #return JSON.toDynamicObjectTreeFromString(resp: data())
    return resp
  }


}

----
# Constructor
https://api.github.com
http://ghe.k33g/api/v3
http://github.at.home/api/v3
----
function GitHubClient = |uri, token| {

  let credentials = match {
    when token isnt null and token: length() > 0 then "token" + ' ' + token
    otherwise null
  }
  return gitHubClient(
    baseUri= uri,
    credentials= credentials
  )
}
