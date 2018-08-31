React for python developers
###########################

:date: 2018-09-01
:category: blog
:authors: tristanC

.. note::

   Please be advised that this article is based on personal experimentation
   without any prior knowledge of React. The information may be incorrect.
   Please use at your own discretion.


In this article I will present what I learned about React
from a Python developer point of view.


Project Structure
-----------------

Applications can be bootstraped using
`create-react-app <https://github.com/facebook/create-react-app#yarn>`_

This sets up a *package.json* file with commands to develop and distribute the
application. This also generates a README.md file with 'get-started'
information.

.. table::

  +------------------+--------------------------+
  | Python           | React                    |
  +==================+==========================+
  | setup.py         | package.json             |
  | setup.cfg        |                          |
  +------------------+--------------------------+
  | requirements.txt | package.json / yarn.lock |
  +------------------+--------------------------+

More information: `Create <https://github.com/facebook/create-react-app#yarn>`_
and `Use react-scripts <https://github.com/facebook/create-react-app/blob/master/packages/react-scripts/template/README.md>`_.


Package Manager
---------------

.. table::


  +-----------------+--------------+
  | Python          | React        |
  +=================+==============+
  | pip install lib | yarn add lib |
  +-----------------+--------------+

Yarn is the pip of JavaScript. The differences are:

* It uses a virtualenv by default named node_modules.
* It installs command line tool in node_modules/.bin/.
* It generates a lock file to pin dependencies' version at install time.

More information about: `Yarn <https://yarnpkg.com/en/docs/usage>`_.


Linter
------

.. table::


  +------------------+---------------------------------+
  | Python           | React                           |
  +==================+=================================+
  | flake8 src/      | eslint --ext .js --ext .jsx src |
  +------------------+---------------------------------+

Example configuration file .eslintrc

.. code-block:: yaml

  parser: babel-eslint
  plugins:
    - standard
    - jest
  rules:
    no-console: off
    semi: [error, never]
    quotes: [error, single]
    lines-between-class-members: error
    space-before-function-paren: error
    react/prop-types: error
    react/jsx-key: error
    react/no-did-mount-set-state: error
    react/no-did-update-set-state: error
    react/no-deprecated: error
  extends:
    # Replace recommened by all or strict for pedantic code style.
    - eslint:recommended
    - plugin:react/recommended
  settings:
    react:
      version: 16.4
  env:
    jest/globals: true
    browser: true


More information about: `ESLint <https://eslint.org/docs/rules/>`_ and
`React lint <https://github.com/yannickcr/eslint-plugin-react#list-of-supported-rules>`_.


Language
--------

.. table::


  +-----------------+--------------+
  | Python          | React        |
  +=================+==============+
  | Python          | ECMAScript 6 |
  +-----------------+--------------+
  | Jinja           | JSX          |
  +-----------------+--------------+

React applications are written in ECMAScript 6 (ES6) and the JSX syntaxt
extension.
ES6 is an improved javascript language, and JSX enables
UI using HTML elements inline.

ES6
...

This python function:

.. code-block:: python

  def add(a, b):
    return (a + b)

can be written as:

.. code-block:: jsx

  function add (a, b) {
    return (a + b)
  }
  // or
  const add = (a, b) => { return (a + b) }
  // or using implicit return
  const add = (a, b) => (a + b)


This python object's variables:

.. code-block:: python

  obj = {'a': 1, 'b': 2}
  a = obj['a']

can be written as:

.. code-block:: jsx

  const obj = {a: 1, b: 2}
  const { a } = obj

This python import statement:

.. code-block:: python

  # import
  import os
  import os.path as path

can be written as:

  import os from 'os'
  import { path } from 'os'


This python array/string manipulation:

.. code-block:: python

  array = [1, 2, 3, 4]
  string = "Hello Python"

  array.remove(2)
  // array is now [1, 3, 4]

  string[6:-2]
  // return "Pyth"

Can be written as:

.. code-block:: jsx

  array.splice(1, 1)
  // splice(starting index, number of elem) removed the 2

  string.slice(6, -2)
  // slice(a, b) is similary to python [a:b]

* `Array reference <https://www.w3schools.com/jsref/jsref_obj_array.asp>`_
* `String reference <https://www.w3schools.com/jsref/jsref_obj_string.asp>`_


Convenient iterators:

.. code-block:: jsx

  const list = [{name: 'a'}, {name: 'b'}, {name: 'c'}]

  list.forEach((item) => {console.log(item.name)})
  // output a, b, c

  list.forEach((item, idx) => {console.log(idx, item.name)})
  // output 1 a, 2 b, 3 c

  list.map((item) => (item.name))
  // return a, b, c

  list.map((item) => {
    if (item.name === 'a') {
       return 'A'
    } else {
       return item.name
    }
  })
  list.map((item) => (item.name === 'a' ? 'A' : item.name))
  list.map((item) => (item.name === 'a' && 'A' || item.name))
  // return A, b, c

  list.filter(item => item.name !== 'a').map(item => item.name)
  list.filter((item, idx) => idx >= 1).map(item => item.name)
  // return b, c

Note: use web console to try code snippets.


JSX
...

This pseudo python code:

.. code-block:: python

  title = 'Hello Python'
  print('<h1>%s</h1>' % title)

Can be written as:

.. code-block:: jsx

  title = 'Hello React'
  return <h1>{title}</h1>

To embed dynamic content in UI elements, use {} delimiter.

.. code-block:: jsx

  const list = [{name: 'a'}, {name: 'b'}, {name: 'c'}]
  return (
    <ul>
      {list.map(item => (<li>item.name</li>))}
    </ul>
  )

More information about: `JSX <https://reactjs.org/docs/introducing-jsx.html>`_.


Component
---------

.. table::


  +-----------------+--------------+
  | Python          | React        |
  +=================+==============+
  | class           | Component    |
  +-----------------+--------------+
  | self            | this         |
  +-----------------+--------------+

React components are similar to Python class,
and they can be used as UI elements.

This pseudo python code:

.. code-block:: python

  class Title:
    def __init__(self, title):
      self.title = title

    def render(self):
      return '<h1>%s</h1>' % self.title

  print(Title('Hello Python').render())

can be written as:

.. code-block:: jsx

   class Title extends React.Component {
     render () {
       const { name } = this.props
       return (<h1>{name}</h1>)
     }
   }
   const title = <Title name='Hello React' />


Notes about components:

* Properties are static attributes given by the parent component:

  * They are set as HTML properties.
  * They are accessed through this.props.
  * They can't be changed.

* Variables are stored in state:

  * They can be initialized as component constructor or class member.
  * They are set using this.setState({variableName: variableValue}).
  * They are accessed through this.state.

* Component lifecycle methods are:

  * **constructor()**: invoked once when the component is created.
    State can be initialized during construction.
  * **render()**: invoked each time the states or property are updated.
    State **can't** be changed during render.
  * **componentDidMount()**: invoked immediately after a component is
    inserted into the tree. State can be changed during componentDidMount.
    Network operations are usualy done here.
  * **componentDidUpdate(prevProps, prevState)**: invoked immediately
    after updating occurs. This method is not called for the initial render.
    Network operations can be done here too. Be careful when updating the state;
    check prevState before to avoid a rendering loop.
  * **componentWillUnmount()**: invoked immediately after a component is
    removed from the tree or destroyed.

Any other component's function is static and *this* (self) reference is not
available.
To bind a function to the instance, you need to use oneline syntax:

.. code-block:: jsx

  class Counter extends React.Component {
    constructor () {
      super()
      this.state = {value: 0}
    }
    // This clicked method doesn't work, it is not binded
    clicked () {
      this.setState({value: this.state.value + 1})
    }
    // This clicked method works
    clicked = () => {
      this.setState({value: this.state.value + 1})
    }
    render () {
      return (
        <Button onClick={this.clicked}>
          {this.state.value}
        </Button>
      )
    }
  }

More information about: `Component <https://reactjs.org/docs/react-component.html#overview>`_.


Immutability
------------

React manages component rendering through state update.
When the state holds complex data like struct or array, you need to
properly update the reference.

.. code-block:: jsx

  state = {
    items = []
    object = {}
  }
  // This doesn't work
  const { item, object } = this.state
  item.push('New item')
  object.name = 'New name'
  this.setState({
    item: item,
    object: object
  })

  // This works because it updates the references
  this.setState({
    items: [ ...items, 'New item' ]
    object: Object.assign({}, object, {name: 'New name'})
  })

The Object.assign and array construction are hard to use, React provides
immutability helpers:

.. code-block:: jsx

  import update from 'react-addons-update'

  newItems = update(items, {$push: ['New item']});
  newObject = update(object, {$merge: {name: 'New name'}})

  // To remove item, splice can be used:
  const items = [1, 2, 3, 4, 5]
  update(items, {$splice: [[1, 1]]}) // Removes 2
  update(items, {$splice: [[1, 1, 0]]}) // Replace 2 by 0
  update(items, {$splice: [[4, 1], [0, 1]]}) // Remove 5 and 1
  // NOTE: $splice parameter order matter, always go from highest index to lowest


More information about: `Immutability <https://reactjs.org/docs/update.html>`_.


Routing
-------

.. table::


  +-----------------+--------------+
  | Python          | React        |
  +=================+==============+
  | argparse/click  | react-router |
  +-----------------+--------------+

To load different components based on users' actions, use react-router:

* The main component needs to be inside a <Router> object.
* The main component uses <Switch> and <Route> to load needed component.
* Navigation is performed with <Link>.


.. code-block:: jsx

  import React from 'react'
  import ReactDOM from 'react-dom'
  import { BrowserRouter as Router } from 'react-router-dom'
  import { withRouter, Link, Redirect, Route, Switch } from 'react-router-dom'

  class PageWelcome extends React.Component {
    render () { return (<h1>Page Welcome</h1>) }
  }
  class PageAbout extends React.Component {
    render () { return (<h1>Page About</h1>) }
  }
  class PageView extends React.Component {
    render () { return (<h1>Show {this.props.match.params.itemName}</h1>) }
  }

  class App extends React.Component {
    render () {
      return (
        <div>
          <ul>
            <li><Link to='/about'>About</Link></li>
            <li><Link to='/view/item1'>Show item 1</Link></li>
            <li><Link to='/view/item42'>Show item 42</Link></li>
          </ul>
          <Switch>
            <Route path='/welcome' component={PageWelcome} />
            <Route path='/about' component={PageAbout} />
            <Route path='/view/:itemName' component={PageView} />
            <Redirect from='*' to='/welcome' key='default-route' />
          </Switch>
        </div>
      )
    }
  }
  export default withRouter(App)

  ReactDOM.render(<Router><App /></Router>,
                  document.getElementById('root'))


Notes about router:

* *BrowserRouter* uses HTML5 URL, *HashRouter* uses '#/' anchor URL.
* The *Switch* selects which page to render based on the URL.
* The *Route* path property can include parameters that are automatically set to
  the props.match.params property.

More information about: `Router <https://reacttraining.com/react-router/web/guides/basic-components>`_.

To serve a BrowserRouter build installed in /usr/share/app,
use this apache configuration:

.. code-block:: pre

  <Directory /usr/share/app>
    Require all granted
  </Directory>
  Alias / /usr/share/app/
  <Location />
    RewriteEngine on
    RewriteBase /
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-l
    RewriteRule . /index.html [L]
  </Location>


HTTP Access
-----------
.. table::


  +-----------------+--------------+
  | Python          | React        |
  +=================+==============+
  | requests        | axios        |
  +-----------------+--------------+

The axios library uses async Promise, here is a demo that fetches the
Software Factory zuul version number:

.. code-block:: jsx

  import React from 'react'
  import Axios from 'axios'

  const url = 'https://softwarefactory-project.io/zuul/api/tenant/local/status'

  class StatusPage extends React.Component {

    state = {
      status: null
    }

    componentDidMount () {
      Axios.get(url)
        .then(response => {
          this.setState({status: response.data})
        })
        .catch(error => {
          console.log('Oops...')
        })
    }

    render () {
      const { status } = this.state
      if (!status) {
        return <p>Loading...</p>
      }
      return <p>Zuul version: {status.zuul_version}</p>
    }
  }

Notes about Axios:

* HTTP Verbs are function name:

  * Axios.post(url, data)
  * Axios.put(url, data)
  * Axios.delete(url)
  * ...

* Axios is better than the standard library, it takes care of json codec and it
  is backward compatible with older browsers.

More information about: `Axios <https://github.com/axios/axios#example>`_.


PatternFly
----------

The patternfly-react module enables React binding.

List view example:

.. code-block:: jsx

  import { ListView } from 'patternfly-react'

  const itemList = [{'title': 'An item', 'content': 'Item content'}]
  const listView = (
    <ListView>
      {itemList.map((item, idx) => (
        <ListView.Item
          heading={item.title}
          additionalInfo={AdditionalInfo}
          hideCloseIcon={true}
          expanded
          >
          {item.content}
        </ListView.Item>
     )}
    </ListView>
  )

Table example:

.. code-block:: jsx

  import { Table } from 'patternfly-react'

  const headFormat = value => <Table.Heading>{value}</Table.Heading>
  const cellFormat = (value) => <Table.Cell>{value}</Table.Cell>
  const columns = [{
    header: {label: 'Title', formatters: headFormat},
    property: 'title',
    cell: {formatters: [cellFormat]}
  }, {
    header: {label: 'Content', formatters: headFormat},
    property: 'content',
    cell: {formatters: [cellFormat]}
  }
  ]
  const table = (
    <Table.PfProvider
       striped
       bordered
       hover
       columns={columns}
       >
       <Table.Header/>
       <Table.Body
          rows={itemList}
          rowKey="title"
          />
    </Table.PfProvider>
  )

Application framework example:

.. code-block:: jsx

  import React from 'react'
  import { withRouter } from 'react-router'
  import { Link, Redirect, Route, Switch } from 'react-router-dom'
  import { Masthead } from 'patternfly-react'

  import logo from './images/logo.png'
  import { routes } from './routes'

  class App extends React.Component {
    constructor () {
      super()
      this.menu = routes()
    }

    renderMenu = () => {
      const { location } = this.props
      const activeItem = this.menu.find(
        item => location.pathname === item.to
      )
      return (
        <ul className="nav navbar-nav navbar-primary">
          {this.menu.filter(item => item.title).map(item => (
            <li key={item.to} className={item === activeItem ? 'active' : ''}>
              <Link to={item.to}>{item.title}</Link>
            </li>
          ))}
        </ul>
      )
    }

    renderContent = () => {
      const allRoutes = []
      this.menu.map((item, index) => {
        allRoutes.push(
          <Route key={index} exact
                 path={item.to}
                 component={item.component} />
        )
        return allRoutes
      })
      return (
        <Switch>
          {allRoutes}
          <Redirect from="*" to="/" key="default-route" />
        </Switch>
      )
    }

    render () {
      return (
        <React.Fragment>
          <Masthead
            iconImg={logo}
            navToggle
            thin
            >
            <div className="collapse navbar-collapse">
              {this.renderMenu()}
              <ul className="nav navbar-nav navbar-utility">
                <li><a href="https://docs.example.com/"
                       rel="noopener noreferrer" target="_blank">
                    Documentation
                </a></li>
              </ul>
            </div>
          </Masthead>
          <div className="container-fluid container-cards-pf">
            {this.renderContent()}
          </div>
        </React.Fragment>
      )
    }
  )
  export default withRouter(App)

  // routes.js
  import Welcome from './pages/Welcome'
  const routes = () => [
    {
      title: 'Welcome',
      to: '/',
      component: Welcome
    },
  ]
  export { routes }


More information about: `Icon lists <https://www.patternfly.org/styles/icons/>`_
`Patterns <https://www.patternfly.org/pattern-library/>`_
and `Patternfly-react <https://rawgit.com/patternfly/patternfly-react/gh-pages/>`_.



Store
-----

To share a global context with any component, use a store with Redux and Thunk.

Redux lets you **dispatch** action and **connect** store to component's properties.
This enables you to access global variable from nested components without having
to pass the property all the way down. This also handles state transition
and it provides powerful management.

Similarly to the react-router *Browser*, the main component needs to be inside
a *Provider* object:

.. code-block:: jsx

   // index.js
  import { Provider } from 'react-redux'

  import { createMyStore } from './reducers'
  import App from './app'

  const store = createMyStore()
  ReactDOM.render(
    <Provider store={store}>
      <Router><App /></Router>
    </Provider>,
    document.getElementById('root'))


Here is a reducer for the "Zuul status fetch" demoed previously:

.. code-block:: jsx

  // reducers.js
  import { createStore, applyMiddleware, combineReducers } from 'redux'
  import thunk from 'redux-thunk'

  // Reducers process action and update state accordingly
  const statusReducer = (state = null, action) => {
    // state = null is the default state
    switch (action.type) {
      case 'FETCH_STATUS_SUCCESS':
        // when success action is dispatched, state becomes status
        return action.status
      default:
        return state
    }
  }
  function createMyStore () {
    // We can have multiple reducers for each context variable.
    return createStore(combineReducers({
      status: statusReducer,
    }), applyMiddleware(thunk))
  }

  // Actions to be dispatched
  function fetchStatusAction () {
    return (dispatch) => {
      return Axios.get(".../zuul/api/tenant/local/status")
        .then(response => {
          dispatch({type: 'FETCH_STATUS_SUCCESS', status: response.data})
        })
        .catch(error => {
          throw (error)
        })
    }
  }
  export {
    createMyStore,
    fetchStatusAction,
  }


Then we can connect the store to a Refresh button and the Status page:

.. code-block:: jsx

   // Status.jsx
   import React from 'react'
   import { connect } from 'react-redux'

   class Status extends React.Component {
     render () {
        const { status } = this.props
        if (!status) {
          return <p>Loading...</p>
        }
        return (
          <p>Zuul version: {status.zuul_version}</p>
        )
     }
   }

   // The connect method binds the store status state to
   // the component status property.
   // When the status changes, the component is automatically updated.
   export default connect(
     state => ({
       status: state.status
     })
   )(Status)


.. code-block:: jsx

   // App.jsx
   import React from 'react'
   import { connect } from 'react-redux'

   import Status from './status'
   import { fetchStatusAction } from './reducers'

   class App extends React.Component {
     render () {
       return (
         <div>
           <button onClick={() => {this.props.dispatch(fetchStatusAction())}}>
             Fetch status
           </button>
           <Status />
         </div>
       )
     }
   }
   // Connect also adds a dispatch function property to dispatch action
   export default withRouter(connect()(App))

More information about: `Redux basics <https://redux.js.org/basics/actions>`_
and `Thunk <https://redux.js.org/advanced/middleware>`_.


Lastly we can write test by using mock action:

.. code-block:: jsx

   // Status.test.jsx
   import React from 'react'
   import ReactTestUtils from 'react-dom/test-utils'
   import { Provider } from 'react-redux'

   import Status from './status'
   import { createMyStore } from '../../reducers'

   it('status render zuul version', () => {
     const store = createMyStore()
     store.dispatch({type: 'FETCH_STATUS_SUCCESS', status: {zuul_version: 42}})
     const component = ReactTestUtils.renderIntoDocument(
       <Provider store={store}>
         <Status />
       </Provider>
     )
     const statusDom = ReactTestUtils.findRenderedDOMComponentWithTag(
       component, 'p')
     expect(statusDom.textContent).toEqual('Zuul version: 42')
   })

More information about: `ReactTestUtils <https://reactjs.org/docs/test-utils.html>`_.


All the references
------------------

* Package management

  * `Yarn <https://yarnpkg.com/en/docs/usage>`_.
  * `Create react app <https://github.com/facebook/create-react-app#yarn>`_.
  * `Use react-scripts <https://github.com/facebook/create-react-app/blob/master/packages/react-scripts/template/README.md>`_.

* Language

  * `Array reference <https://www.w3schools.com/jsref/jsref_obj_array.asp>`_.
  * `String reference <https://www.w3schools.com/jsref/jsref_obj_string.asp>`_.
  * `ESLint <https://eslint.org/docs/rules/>`_ and `React lint <https://github.com/yannickcr/eslint-plugin-react#list-of-supported-rules>`_.

* React

  * `Main concepts <https://reactjs.org/docs/hello-world.html>`_.
  * `JSX <https://reactjs.org/docs/introducing-jsx.html>`_.
  * `Component <https://reactjs.org/docs/react-component.html#overview>`_.
  * `Immutability <https://reactjs.org/docs/update.html>`_.
  * `Router <https://reacttraining.com/react-router/web/guides/basic-components>`_.
  * `Axios <https://github.com/axios/axios#example>`_.
  * `ReactTestUtils <https://reactjs.org/docs/test-utils.html>`_
  * `Testing React Component <http://reactkungfu.com/2015/07/approaches-to-testing-react-components-an-overview/>`_

* Redux

  * `Redux basics <https://redux.js.org/basics/actions>`_.
  * `Thunk <https://redux.js.org/advanced/middleware>`_.

* PatternFly

  * `Icon lists <https://www.patternfly.org/styles/icons/>`_.
  * `Patterns <https://www.patternfly.org/pattern-library/>`_.
  * `React bootstrap <https://react-bootstrap.github.io/components/forms/>`_.
  * `Patternfly-react <https://rawgit.com/patternfly/patternfly-react/gh-pages/>`_.
  * `Patternfly react sources <https://github.com/patternfly/patternfly-react>`_
    are sometime needed to search for actual mock example.


* My demo applications

  * `Zuul web interface <https://review.openstack.org/591604>`_.
  * `LogClassify web interface <https://softwarefactory-project.io/cgit/logreduce/tree/web>`_.
  * `Zuul tenant tests <https://review.openstack.org/#/c/591604/24/web/src/App.test.jsx>`_.
    and `Zuul change panel test <https://review.openstack.org/#/c/591604/24/web/src/containers/status/ChangePanel.test.jsx>`_.
  * `Anomaly report form <https://softwarefactory-project.io/cgit/logreduce/tree/web/src/pages/UserReport.jsx>`_.


I hope you find this application stack as interesting as I do.
That's it folks!
