---
layout: post
title: 网页信息检索入门：从看懂页面到快速筛选信息
date: 2026-05-10
description: 从 F12 开发者工具的好奇出发，沿请求、响应、解析与显示理解网页运作，认识 HTML、CSS、JavaScript 和 HTTP 状态码，再用 Network 观察查询与筛选信息。
tags: [Python, 网页, 信息检索, 自学]
categories: [学习笔记]
featured: false
toc:
  sidebar: left
---

最初让我好奇的是浏览器里的 F12 开发者工具。平时看到的网页是按钮、列表和输入框，打开这个面板之后，却能看到 HTML 标签、样式、脚本，以及一条条正在发生的网络请求。我开始想知道：眼前这个页面到底是怎样被拼出来的？点击按钮之后，浏览器又做了什么？

爬虫技术进一步勾起了我的兴趣：如果不用在界面上逐个点击，也能通过程序获取和筛选信息，那么这些程序究竟是在和谁交互？它们怎样找到数据，又为什么有时拿到了网页，却找不到浏览器里显示的内容？

带着这些好奇，我尝试用 Python 整理公开网页中的信息，也在排错过程中逐渐理解了网页背后的运作方式。这篇笔记从网页的组成与加载过程讲起，再介绍怎样观察数据请求、复现查询，并把结果整理成可筛选的表格。示例统一使用虚构的信息目录。

*根据 2026 年 5 月 10 日与 Agent 的对话整理。*

## 网页的组成：结构、样式与行为

网页通常由 HTML、CSS 和 JavaScript 配合构成。它们可以写在同一个 HTML 文件中，也可以拆成浏览器分别下载的文件。

| 组成 | 负责什么 | 在信息列表中的例子 |
| --- | --- | --- |
| HTML | 描述内容与结构：标题、段落、链接、表单等 | 一个搜索框、一组分类按钮、一个列表容器 |
| CSS | 描述样式与布局：颜色、字体、间距、排列方式等 | 让列表排成卡片，给选中的分类换一种颜色 |
| JavaScript | 执行程序逻辑：处理交互、请求数据、修改页面等 | 读取关键词，发送查询，把返回的条目填进列表 |

例如，HTML 可以先提供这样的骨架：

```html
<input id="keyword" placeholder="输入关键词" />
<button id="search">搜索</button>
<ul id="results"></ul>
```

这里有输入框、按钮和一个空列表，但按钮还没有查询逻辑，列表也没有结果。CSS 可以改变它们的外观；JavaScript 则可以在点击按钮后读取关键词、获取结果并更新列表。也有网站直接把条目写进 HTML，不需要额外请求就能看到内容。

理解这三者之后，再把它们放回一次真实的页面加载过程，就能看清“拿到文件”和“看到页面”之间发生了什么。

## 网页加载的阶段：从地址到屏幕上的内容

可以先沿着这条主线理解：

```text
输入地址或点击链接
    ↓
浏览器定位服务器、建立连接，发送 HTTP 请求
    ↓
服务器处理请求，返回状态码、响应头和响应体
    ↓
浏览器解析 HTML，构建 DOM，并加载样式、脚本等资源
    ↓
结合样式计算布局，把页面绘制到屏幕
    ↓
JavaScript 响应交互，也可能继续请求数据、修改 DOM
    └──→ 更新布局与显示
```

这是一条便于学习的主线。实际浏览器会让下载、解析和显示交错进行，并不一定等所有文件下载完才开始显示。

### 阶段一：浏览器发起请求

输入 `https://example.com/catalog/` 后，在需要联网的情况下，浏览器会通过 DNS 等机制确定服务器地址、建立连接，并为 HTTPS 建立加密通信。已有连接和缓存也可能被复用。

接下来，浏览器发送 HTTP 请求。理解一个请求，先看四个部分：

| 部分 | 表达的内容 | 例子 |
| --- | --- | --- |
| 方法 | 这次要执行哪类操作 | 打开页面常见 GET，提交查询也可能用 POST |
| URL | 请求哪个资源，可以附带查询参数 | `/catalog/?category=tools` |
| 请求头 | 描述请求上下文与数据格式等 | `Accept`、`Content-Type` |
| 请求体 | 随请求提交的数据；不一定存在 | 搜索条件、分页参数等 |

网页上的按钮只是触发操作的入口。程序如果能按相同规则构造查询请求，也就可能获取界面使用的数据。这正是我好奇的“绕过 UI 操作”的一个常见原理。

### 阶段二：服务器处理请求并返回响应

请求到达服务器之后，可能经过代理或网关，再由网站程序读取路径、参数和请求体。程序可能查询数据库、读取文件，或调用其他服务，然后生成响应。

响应同样有可以辨认的结构：

| 部分 | 表达的内容 | 例子 |
| --- | --- | --- |
| HTTP 状态码 | 这次请求的处理结果类别 | `200`、`404`、`500` |
| 响应头 | 描述返回内容及缓存等信息 | `Content-Type: text/html` |
| 响应体 | 实际返回的数据 | HTML 文档、JSON 数据、图片或错误说明 |

**状态码属于响应，不是浏览器解析网页之后生成的判断。** 它也不全是“错误码”：`200` 表示成功，`3xx` 通常涉及重定向或缓存处理，`4xx`、`5xx` 才是错误响应。后文会按首位数字展开。

服务器返回 HTML 时，可以已经把数据填好；也可以只返回页面骨架，让浏览器稍后再请求数据。收到响应，才进入浏览器这一侧的解析与显示。

### 阶段三：浏览器解析 HTML，建立 DOM

浏览器的 HTML 解析器会把收到的文档解析为 **DOM（Document Object Model，文档对象模型）**。可以把它理解成一棵在内存中的结构树：页面包含哪些元素、谁是谁的子元素、元素有什么属性和文字，都在树中表示。

前面的示例会形成输入框、按钮和列表等节点。HTML 解析器在文档中遇到 CSS、脚本、图片的引用时，浏览器还会安排加载这些资源。

因此，解析 HTML 得到的是可以供程序访问和修改的页面结构；图片内容、脚本运行后补入的数据等，并不会凭空出现在最初的 HTML 中。

### 阶段四：解析样式，计算布局并绘制

浏览器解析 CSS，建立样式规则的表示（CSSOM），再结合 DOM 计算元素应该使用的样式、占多大空间、放在哪里，最终把文字、边框、图片等绘制并合成到屏幕上。

这解释了为什么只有 HTML 也可能显示出文字和链接，但看起来和完整网页不同：它提供了结构与内容，而页面的布局和外观还依赖样式、图片等资源。浏览器也会提供默认样式。

### 阶段五：执行 JavaScript，按需加载并更新页面

JavaScript 可以读取或修改 DOM，也可以通过 Fetch/XHR 向服务器发送新的请求。对于动态列表，常见过程是：

```text
页面脚本启动，或用户点击“搜索”
    → JavaScript 读取筛选条件
    → 发送数据查询请求
    → 服务器返回 JSON
    → JavaScript 解析 JSON，生成或更新列表节点
    → 浏览器更新页面显示
```

这里有两种不同的解析：**HTML 解析产生页面结构，JSON 解析产生程序可使用的数据对象**。JSON 本身不会自动变成卡片或表格，需要网页代码把数据转成 DOM 中的内容。

脚本的执行时机取决于加载方式，有的会暂停 HTML 解析，有的稍后执行；它并不一定都发生在第一次绘制之后。这里把它单列，是为了看清它怎样让网页继续变化。加载和渲染过程可对照 [MDN 的浏览器工作原理说明](https://developer.mozilla.org/en-US/docs/Web/Performance/Guides/How_browsers_work)。

### 对应到信息检索工具

有了这条阶段链，再看工具的分工就清楚了：

| 工具或面板 | 对应的工作 | 能观察或得到什么 |
| --- | --- | --- |
| requests | 发送 HTTP 请求、接收响应 | 状态码、响应头、HTML 或 JSON 等响应内容 |
| BeautifulSoup | 解析已经取得的 HTML | 标签结构、文字、属性和链接；不执行网页脚本 |
| 浏览器 Elements 面板 | 查看当前 DOM | 包括 JavaScript 后续修改过的页面结构 |
| 浏览器 Network 面板 | 记录页面与资源的数据交换 | 初始文档、样式、脚本、接口等请求与响应 |
| Selenium | 驱动浏览器加载页面并执行交互 | 在正确等待之后，访问脚本执行后的页面状态 |

**浏览器里看得到的信息，不一定就在第一次请求返回的 HTML 中。** 接下来遇到的第一次失败，就和这个区别有关。

## 第一次失败：拿到了 HTML，为什么提取结果还是空的？

原记录里出现了一个很有迷惑性的现象：普通请求找到了 33 个“可能的条目”，自动化浏览器找到了 46 个，但最终提取结果都是空的。

这两个数字只说明某些标签匹配了代码里的条件，**不能证明找到了目标内容**。用 `item`、`card`、`box` 这类宽泛的类名猜选择器，很容易把导航、筛选按钮、页脚一起选进来。

正确的下一步是保存响应，检查内容：

```python
from pathlib import Path
import requests

# 示例地址；实际使用时替换为你已确认可访问的列表页。
response = requests.get("https://example.com/catalog/", timeout=15)
response.raise_for_status()
Path("page_source.html").write_bytes(response.content)
```

在保存的文件中搜索一个浏览器里真实可见、辨识度较高的标题，然后判断：

- **找得到标题及其条目结构**：先核对选择器。例如 `.entry .title a` 表示在条目内找标题链接，不能拿它当所有网站通用的规则。
- **只有空容器和脚本引用**：动态加载是一个值得验证的方向，接下来观察网络请求。
- **返回了登录页、错误页或验证页**：先解决访问状态，不能拿它当正常列表继续解析。

原记录后续找到了返回结构化数据的请求，支持了动态加载这个判断。但“结果为空”本身还不足以直接下结论。

还有一个独立的小问题：Python 报了 `SyntaxWarning: invalid escape sequence`。它可能来自包含 `\.` 的普通字符串，甚至只是说明文字里的写法。正则表达式可以写成原始字符串 `r"\."`，或者在普通字符串里写 `"\\."`。这个警告值得修正，但并不能解释为什么网页条目没有被正确提取。

## 用 Network 找数据：应该看哪个栏目？

不需要先学完整个前端开发。先学会回答一个问题：**我点击筛选时，浏览器到底向服务器发送了什么，又收到了什么？**

在 Chrome 中打开开发者工具，进入 **Network（网络）**：

1. 清空当前请求列表，选择 **Fetch/XHR** 过滤器。
2. 保持面板打开，刷新页面，或只执行一次筛选、翻页操作。
3. 点击新出现的请求，查看返回内容是否包含刚才看到的标题。
4. 如果没有候选，切回 **All**。数据也可能在文档响应中，或者筛选完全发生在本地，并未产生新请求。

找到候选后，重点看这些位置：

| 栏目 | 要确认的内容 |
| --- | --- |
| Headers → General | Request URL、Request Method、Status Code |
| Headers → Request Headers | 请求的 Content-Type，以及是否依赖登录状态等上下文 |
| Payload → Query String Parameters | URL 问号后面的参数 |
| Payload → Form Data / Request Payload | 请求体到底是表单还是其他格式 |
| Preview | 方便展开查看数据层级 |
| Response | 服务器实际返回的文本，核对字段与错误信息 |

这些位置可对照 [Chrome 官方 Network 参考文档](https://developer.chrome.com/docs/devtools/network/reference/#payload)。

接口不一定以 `.json` 结尾，名字里也不一定带 `api`。判断依据是响应是否包含目标信息，以及筛选动作与参数变化是否对应。

我会先切换一次分类，再翻一次页，比较两次请求。这样才能知道哪个参数负责分类、哪个负责分页，而不是靠字段名猜。

## 最关键的区别：URL 参数、表单和 JSON 是三回事

原记录里，在找到请求地址后，程序最初只复现了一个查询参数。后续查看 Payload 才发现，浏览器还发送了站点编号、筛选条件、返回字段、排序规则和分页信息。

只复制地址，就像照着收件地址寄出一个空信封：目的地对了，查询所需的内容却没有带上。

下面是一个**虚构的同类请求**：

```text
POST https://example.com/api/search?queryObj=catalog
Content-Type: application/x-www-form-urlencoded

Form Data（解码后）：
siteId: demo
conditions: [{"field":"category","value":"工具","judge":"="}]
returnInfos: [{"field":"title","name":"title"}]
pageIndex: 1
rows: 20
```

这里同时出现了三层信息：

- `queryObj=catalog` 是 **URL 查询参数**。
- `siteId`、`pageIndex`、`rows` 等构成**表单请求体**。
- `conditions` 和 `returnInfos` 是**表单字段里的 JSON 字符串**。

字段值长得像 JSON，不代表整个请求体就是 JSON。在 Requests 中，`params=` 用于 URL 参数，`data=` 传字典时会进行表单编码，`json=` 则发送 JSON 请求体；具体行为见 [Requests 官方快速入门](https://requests.readthedocs.io/en/latest/user/quickstart/#more-complicated-post-requests)。

可以先在本地构造请求，检查它会怎样编码，完全不发送网络请求：

```python
import json
import requests

form = {
    "siteId": "demo",
    "conditions": json.dumps([
        {"field": "category", "value": "工具", "judge": "="}
    ], ensure_ascii=False),
    "returnInfos": json.dumps([
        {"field": "title", "name": "title"}
    ]),
    "pageIndex": "1",
    "rows": "20",
}

request = requests.Request(
    "POST",
    "https://example.com/api/search",
    params={"queryObj": "catalog"},
    data=form,
).prepare()

print(request.url)
print(request.headers["Content-Type"])
print(request.body)
```

预期 URL 带有 `?queryObj=catalog`，Content-Type 为 `application/x-www-form-urlencoded`。请求体中的中文、方括号等字符会被编码，这是正常现象。`prepare()` 只生成请求，不会发出它。

实际复现时，用 Network 中确认的地址与参数调用 `requests.post(..., params=..., data=..., timeout=15)`。上面字段全部属于教学约定，不能照搬到任意网站；也不要为了“更像浏览器”盲目复制所有请求头。

## HTTP 状态码：先看首位，再读具体含义

HTTP 状态码是三位数字。**第一位表示类别，完整三位才确定具体含义**。所以看到 `503` 时，可以先知道它属于 `5xx` 服务端错误，再去看 `503` 具体表示什么。

### 首位数字划分的五类响应

| 范围 | 类别 | 怎样理解 | 常见例子 |
| --- | --- | --- | --- |
| 100–199 | 信息性响应 | 通信过程中的中间提示，通常还要继续等待最终响应 | `100 Continue`：可以继续发送请求体 |
| 200–299 | 成功响应 | 请求已被成功接收、理解并接受；具体完成到哪一步仍看完整状态码 | `200 OK`、`201 Created`、`202 Accepted`、`204 No Content` |
| 300–399 | 重定向类响应 | 通常要换地址或结合缓存完成处理 | `301` 永久重定向、`302` 临时重定向、`304 Not Modified` |
| 400–499 | 客户端错误响应 | 请求、身份、权限或目标资源等方面存在问题，需要检查请求条件 | `400` 请求有误、`401` 需要认证、`403` 拒绝访问、`404` 未找到、`429` 请求过多 |
| 500–599 | 服务端错误响应 | 服务器或处理链上的中间服务未能完成请求 | `500` 内部错误、`502` 网关错误、`503` 服务不可用、`504` 网关超时 |

这里的“客户端”可以是浏览器，也可以是 Python 程序。`4xx`、`5xx` 是协议层面的分类，不能据此直接认定是哪一个人写错了代码。

表中的 `202` 只表示已接受处理，不保证处理已经完成；`204` 表示成功但没有响应内容；`304` 属于 `3xx`，却不是让浏览器跳到新网址，而是告诉它可使用已有缓存。不能把一类中的所有状态都当成完全相同的结果。完整定义可查 [MDN 的 HTTP 状态码参考](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status)。

### 浏览器跳转，为什么程序里最后只看到了 200？

访问旧地址时，服务器可能先返回 `301` 或 `302`，并在 `Location` 响应头中提供新地址。浏览器通常继续请求新地址，如果后续成功，就会显示新页面。

Requests 对常见请求也会默认跟随重定向，因此 `response.status_code` 可能只是最终响应的状态码。排查时可以同时看 `response.url` 和 `response.history`，确认是否跳到了登录页或其他地址。

所以，最终得到 `200` 并不保证拿到的就是原本想要的内容。它可能是一份成功返回的登录页。

### 500、502、503、504 分别指向什么？

- **500 Internal Server Error**：服务器遇到了意外情况，无法完成请求。这是比较笼统的错误，单凭它无法知道是程序异常、数据处理失败还是其他原因。
- **502 Bad Gateway**：作为网关或代理的服务器，从上游服务收到了无效响应。一个网站背后可能有多个服务，错误可能发生在它们之间。
- **503 Service Unavailable**：服务当前无法处理请求，常见于暂时过载或维护。响应可能带有 `Retry-After`，提示多久以后再尝试；遇到它应先检查提示，避免连续重试。
- **504 Gateway Timeout**：网关或代理未能及时等到上游响应。它和本地程序自己等待超时是两种情况：前者已经收到了 HTTP 响应，后者可能根本没有收到状态码。

这些是标准含义。实际网站也可能没有准确使用状态码，因此还要查看响应体，并与浏览器中的请求进行对比。

### HTTP 状态与业务状态要分开读

原记录中，简化后的请求先出现 HTTP `500`，后续调试出现 HTTP `503`，响应体中还有类似下面的内容：

```json
{"error": "未查询到结果！", "result": false, "status": -3}
```

这里有两层信息：

| 层次 | 本例中的值 | 谁定义其含义 |
| --- | --- | --- |
| HTTP 状态码 | `503` | HTTP 协议，表示服务不可用 |
| 业务状态与说明 | `result: false`、`status: -3`、`error` | 这个网站自己的接口约定 |

JSON 里的 `status: -3` 不是 HTTP 状态码，也没有跨网站通用的含义。“未查询到结果”提供了一条线索，却不能单独证明服务器为什么失败。

同样，如果接口返回 HTTP `200`，但响应体写着 `result: false`，就只能说明 HTTP 请求成功返回了内容，业务查询仍然失败。一个正常查询也可能成功返回空列表，需要结合接口约定判断。

对这份记录来说，能确认的请求差异是：**浏览器发送了完整表单，早期程序没有**。因此，下一步应先补齐请求结构，再验证结果。原回答直接把错误归因为“缺少参数”，证据还不足；最终方案也仍需要实际运行验证。

### 按响应所处的层次排查

1. **有没有收到 HTTP 响应？** 先区分 DNS、连接或本地超时等异常，与已经收到的 `4xx`、`5xx` 响应。
2. **状态码属于哪一类？** `3xx` 检查跳转，`4xx` 检查请求与访问条件，`5xx` 同时考虑服务端状态和请求差异。
3. **返回的是预期内容吗？** 核对最终 URL、响应的 Content-Type，以及响应体是否其实是登录页或错误说明。
4. **请求是否完整复现？** 比较方法、URL 参数、请求体编码、分类、分页、站点标识等；这些一致后再检查必要的会话上下文。
5. **业务结果是否成立？** 最后检查成功标记、数据结构和实际条数，区分正常空结果与失败。

这样，状态码就成了定位问题所处阶段的线索，也能避免一报错就换工具、反复尝试同一个不完整的请求。

## 拿到数据后，怎样变成可筛选的表格？

先观察真实响应的层级，再写字段映射。`exField4` 之类的名字无法自己说明含义，必须拿页面展示和返回值逐一核对。

下面是一段**可以离线运行的完整练习**，只使用 Python 标准库。数据为虚构条目，用来练习校验、关键词筛选、去重和导出，不代表原对话已经取得这些结果。

```python
import csv
import json

sample_response = r'''
{
  "result": true,
  "data": [
    {"category": "工具", "title": "网页检索入门",
     "summary": "理解页面结构与信息筛选", "url": "https://example.com/a"},
    {"category": "笔记", "title": "整理公开信息的方法",
     "summary": null, "url": "https://example.com/b"},
    {"category": "工具", "title": "网页检索入门",
     "summary": "理解页面结构与信息筛选", "url": "https://example.com/a"}
  ]
}
'''

payload = json.loads(sample_response)
if not isinstance(payload, dict) or payload.get("result") is not True:
    raise ValueError("响应没有确认查询成功")

items = payload.get("data")
if not isinstance(items, list):
    raise ValueError("data 应当是列表，请重新核对响应结构")

def text(value):
    return "" if value is None else str(value).strip()

def csv_cell(value):
    # CSV 用于电子表格查看时，避免文本被当作公式执行。
    value = text(value)
    return "'" + value if value.lstrip().startswith(("=", "+", "-", "@")) else value

keyword = "检索"
rows = []
seen = set()
for item in items:
    if not isinstance(item, dict):
        raise ValueError("条目应当是对象，请检查数据")
    title = text(item.get("title"))
    summary = text(item.get("summary"))
    url = text(item.get("url"))
    if keyword.casefold() not in f"{title} {summary}".casefold():
        continue
    key = url or (text(item.get("category")), title)
    if key in seen:
        continue
    seen.add(key)
    rows.append({
        "分类": text(item.get("category")),
        "标题": title,
        "摘要": summary,
        "来源链接": url,
    })

with open("search_results.csv", "w", newline="", encoding="utf-8-sig") as file:
    writer = csv.DictWriter(file, fieldnames=["分类", "标题", "摘要", "来源链接"])
    writer.writeheader()
    writer.writerows({key: csv_cell(value) for key, value in row.items()} for row in rows)

print(f"原始 {len(items)} 条，筛选去重后 {len(rows)} 条")
```

这段练习应输出“原始 3 条，筛选去重后 1 条”，并在运行目录生成 `search_results.csv`。清空 `keyword` 可以保留全部条目，再到表格软件里筛选。

`utf-8-sig` 有助于部分表格软件识别中文编码；`newline=""` 让 CSV 写入器处理换行。保留来源链接，则能在筛选后返回原页核实。

真实查询还要检查分页。`rows=999` 只是向服务器申请每页返回这么多条，不保证拿到全部数据。服务器可能设置上限，仍需对照总数、页码和实际返回数量。先确认一页，再按实际分页规则低频读取，最后检查重复项与缺失项。

## robots.txt：运行前应该知道的规则

原对话里我还追问了 `robots.txt`。它通常位于同一源的根路径，例如 `https://example.com/robots.txt`，不是每个网站都有。其核心规则由 [RFC 9309：Robots Exclusion Protocol](https://www.rfc-editor.org/rfc/rfc9309.html) 定义。

```text
User-agent: *
Disallow: /internal/
Allow: /public/
```

`User-agent` 指定适用的机器人，`Disallow` 和 `Allow` 描述路径规则。匹配时优先考虑更具体、匹配更长的规则；不能简单理解成 `Allow` 永远优先。它也不是身份认证或访问权限机制。

原记录把“没有文件”和“请求失败”混在了一起，教程里需要分清：404 与网络错误、5xx 的含义不同。按照 RFC，对服务器或网络故障导致的不可达情况，应按禁止访问处理，而不能打印一句“继续执行”。

`Crawl-delay` 是部分实现支持的扩展，并非 RFC 9309 的核心指令；不同工具的支持程度也不同。开始自动化请求前，应确认适用规则与网站使用要求，设置超时和合理间隔，遇到限流或访问拒绝时停止并检查。

## 什么时候才需要 Selenium？

如果页面内容已经在 HTML 中，先用 requests 与 BeautifulSoup。如果 Network 已确认有可复现的数据查询，先理解并复现请求。如果确实依赖浏览器交互或脚本执行，再考虑 Selenium。

用 Selenium 时，需要等待**实际目标条目出现**，而不只是等页面打开，或者固定睡几秒。即使浏览器执行了 JavaScript，错误的选择器也仍然会返回空结果。

对这次学习而言，最有价值的转折发生在打开 Network 之后：原来“页面上有一个列表”可以继续拆解为“哪个请求返回了它”“哪些参数决定筛选结果”“程序是否完整表达了同一个查询”。

## 动手前的检查清单

- 确认 Python 与依赖安装在同一个环境：请求示例使用 `python -m pip install requests`；离线练习不需要第三方库。
- 先手动完成一次查询，记下预期标题和分类，作为比对样本。
- 核对请求方法、参数位置和编码方式，先复现一页。
- 区分网络失败、业务失败和正常空结果，不把它们统一吞掉。
- 核对字段含义、分页数量、重复项和缺失项，再整理成表格。
- 用几条记录回到原网页抽查，确认筛选结果仍然可追溯。

以后遇到陌生网页，我会先保存一次响应，再观察一次交互对应的请求。这样，后面的代码就有了可以核对的依据。
