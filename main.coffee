window.onload = ->
    player_id = location.hash.slice(1)
    players = { }
    players[player_id] = undefined
    player_connections = {}

    peer = new Peer(player_id, {key: 'bt01ki4in04tpgb9', debug:3})

    if player_id != "0"
        other_id = "0"
        player_connections[other_id] = null
        peer.on 'open', ->
            player_connections[other_id] = peer.connect(other_id)
            setup_other_conn(other_id)

    # set the scene size
    WIDTH = window.innerWidth
    HEIGHT = window.innerHeight

    # set some camera attributes
    VIEW_ANGLE = 45
    ASPECT = 1 #Temporary, reset below
    NEAR = 0.1
    FAR = 10000

    # get the DOM element to attach to
    # - assume we've got jQuery to hand
    $container = $("#container")

    # create a WebGL renderer, camera
    # and a scene
    renderer = new THREE.WebGLRenderer()
    cameras = [
        new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR),
        new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR),
        new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR),
        new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
        ]
    scene = new THREE.Scene()

    # the camera starts at 0,0,0 so pull it back
    cameras[1].position.z = 300
    cameras[2].position.x = 300
    cameras[3].position.y = 1000
    cameras[3].rotation.x = -Math.PI/2

    # start the renderer
    renderer.setSize WIDTH, HEIGHT

    # attach the render-supplied DOM element
    $container.append renderer.domElement

    # create the sphere's material
    colors = [0xCC0000, 0x00CC00, 0x0000CC, 0xCCCC00, 0xCC00CC, 0x00CCCC]

    cubeGeometry = new THREE.CubeGeometry(100, 100, 100)

    for camera,i in cameras
        material = new THREE.MeshLambertMaterial(color:colors[i%colors.length])
        cube = new THREE.Mesh(cubeGeometry, material)
        camera.add cube
        scene.add camera

    wallMaterial = new THREE.MeshLambertMaterial(0xCCCCCC)
    wallMaterial.side = THREE.DoubleSide
    floor = new THREE.Mesh(new THREE.PlaneGeometry(1000, 1000), wallMaterial)
    floor.rotation.x = -Math.PI/2
    floor.position.y = -100
    scene.add floor
    walls_data = [ [ 0, -100 ] ]
    walls = []
    for wall_data in walls_data
        wall = new THREE.Mesh(new THREE.PlaneGeometry(100, 500), wallMaterial)
        wall.position.x = wall_data[0]
        wall.position.z = wall_data[1]
        scene.add wall
        walls.push wall


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
      views_x = Math.ceil(Math.sqrt(cameras.length))
      views_y = views_x
      view_width = WIDTH/views_x
      view_height = HEIGHT/views_y
      renderer.enableScissorTest(true)
      for camera,i in cameras
          x = i%views_x
          y = Math.floor(i/views_y)
          camera.aspect = view_width/view_height
          # FIXME don't do this every frame
          camera.updateProjectionMatrix()
          renderer.setViewport(x*view_width, y*view_height, view_width, view_height)
          renderer.setScissor(x*view_width, y*view_height, view_width, view_height)
          renderer.render scene, camera

    $(document).keydown (event) ->
        camera = cameras[player_id]
        old_position = camera.position.clone()
        old_rotation = camera.rotation.clone()
        switch event.which
            when 90 then camera.rotation.y += 0.1
            when 88 then camera.rotation.y -= 0.1
            when 37
                camera.position.x -= 10*Math.cos(camera.rotation.y)
                camera.position.z += 10*Math.sin(camera.rotation.y)
            when 38
                camera.position.x -= 10*Math.sin(camera.rotation.y)
                camera.position.z -= 10*Math.cos(camera.rotation.y)
            when 39
                camera.position.x += 10*Math.cos(camera.rotation.y)
                camera.position.z -= 10*Math.sin(camera.rotation.y)
            when 40
                camera.position.x += 10*Math.sin(camera.rotation.y)
                camera.position.z += 10*Math.cos(camera.rotation.y)
        if false # if collision
            camera.position = old_position
            camera.rotation = old_rotation

        for other_id,player_connection of player_connections
          player_connection.send(
            event: 'move',
            player_id: player_id,
            # FIXME
            position_x: cameras[player_id].position.x,
            position_y: cameras[player_id].position.y,
            position_z: cameras[player_id].position.z,
            rotation_x: cameras[player_id].rotation.x,
            rotation_y: cameras[player_id].rotation.y,
            rotation_z: cameras[player_id].rotation.z
          )

    peer.on('connection', (conn) ->
        console.log(conn)
        player_connections[conn.peer] = conn
        setup_other_conn(conn.peer)
    )

    
    # FIXME
    setup_other_conn = (other_id) ->
        player_connections[other_id].on 'open', ->
            player_connections[other_id].send(
                event: 'players',
                players: players
            )
        player_connections[other_id].on('data', (data) ->
            switch data.event
                when 'move'
                    cameras[data.player_id].position.x = data.position_x
                    cameras[data.player_id].position.y = data.position_y
                    cameras[data.player_id].position.z = data.position_z
                    cameras[data.player_id].rotation.x = data.rotation_x
                    cameras[data.player_id].rotation.y = data.rotation_y
                    cameras[data.player_id].rotation.z = data.rotation_z
                when 'players'
                    for k,v of data.players
                        players[k] = v
        )


    # draw!
    animate()
 
