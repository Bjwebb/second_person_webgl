window.onload = ->
  # set the scene size
  WIDTH = 800
  HEIGHT = 600

  # set some camera attributes
  VIEW_ANGLE = 45
  ASPECT = WIDTH / HEIGHT
  NEAR = 0.1
  FAR = 10000

  # get the DOM element to attach to
  # - assume we've got jQuery to hand
  $container = $("#container")

  # create a WebGL renderer, camera
  # and a scene
  renderer = new THREE.WebGLRenderer()
  camera = new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
  scene = new THREE.Scene()

  # the camera starts at 0,0,0 so pull it back
  camera.position.z = 300

  # start the renderer
  renderer.setSize WIDTH, HEIGHT

  # attach the render-supplied DOM element
  $container.append renderer.domElement

  # create the sphere's material
  sphereMaterial = new THREE.MeshLambertMaterial(color: 0xCC0000)

  # set up the sphere vars
  radius = 50
  segments = 16
  rings = 16

  # create a new mesh with sphere geometry -
  # we will cover the sphereMaterial next!
  sphere = new THREE.Mesh(new THREE.SphereGeometry(radius, segments, rings), sphereMaterial)
  scene.add sphere

  floor = new THREE.Mesh(new THREE.PlaneGeometry(1000, 1000), sphereMaterial)
  floor.rotation.x = -Math.PI/2
  floor.position.y = -100
  scene.add floor


  # and the camera
  scene.add camera

  # create a point light
  pointLight = new THREE.PointLight(0xFFFFFF)

  # set its position
  pointLight.position.x = 10
  pointLight.position.y = 50
  pointLight.position.z = 130

  # add to the scene
  scene.add pointLight

  animate = ->
    requestAnimationFrame animate
    render()

  render = ->
    renderer.render scene, camera

  $(document).keydown (event) ->
    switch event.which
      when 37 then camera.rotation.y += 0.1
      when 38
        camera.position.x -= 10*Math.sin(camera.rotation.y)
        camera.position.z -= 10*Math.cos(camera.rotation.y)
      when 39 then camera.rotation.y -= 0.1
      when 40
        camera.position.x += 10*Math.sin(camera.rotation.y)
        camera.position.z += 10*Math.cos(camera.rotation.y)
    
  # draw!
  animate()

