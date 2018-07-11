# 20180711_Day22

- 무제한 으로 들어가는거 막기 ( 한 유저는 방 하나에 한번만 들어갈 수 있음)

- 현재 이미 채팅방에 참여한 사람은 Join 버튼 안보이게 막기

  

*app/models/user.rb*

```ruby
...
  def joined_room?(room)
    self.chat_rooms.include?(room)
  end
...
```



*app/controllers/chat_rooms_controller.rb*

```ruby
...
  def user_admit_room
    # 현재 유저가 있는 방에서 join 버튼을 눌렀을 때 동작하는 액션
    # 이미 조인되어 있는 유저라면?
    # 이미 참가한 방입니다. 라고 alert를 띄워주고
    # 아닐 경우에는 참가시킨다.
    
    if current_user.joined_room?(@chat_room)
      # @chat_room.user_admit_room(current_user)
            # => 방에 참가하고 이는 유저들 중에 이 유저가 포함되어있나?
      # 이미 조인되어있는 유저라면?
      # => 유저가 참가하고 있는 방의 목록중에 이 방이 포함되어있나?
      # current_user.chat_rooms.where(id: params[:id])[0].nil?
      render js: "alert('이미 참여한 방입니다')"
    else
    end
    @chat_room.user_admit_room(current_user)
  end
...
```



*app/views/chat_rooms/show.html.erb*

```erb
...
<% unless current_user.joined_room?(@chat_room) %>   
  <%= link_to 'Join', join_chat_room_path(@chat_room), method: 'post', remote: true, class: "join_room" %> | 
<% end %>
<%= link_to 'Edit', edit_chat_room_path(@chat_room) %> |
<%= link_to 'Back', chat_rooms_path %>
...
```



#### chat_room을 고유하게 만들어주기 

*app/models/admission.rb*

```ruby
...
    def user_joined_chat_room_notification
       Pusher.trigger("chat_room_#{self.chat_room_id}", 'join', {chat_room_id: self.chat_room_id, email: self.user.email}.as_json)  # self.~~  추가
    end
...
```

- 기존의 *admission*의 코드를수정해야한다. 각 방에서 일어나는 이벤트는 각 방에서만 발생해야 한다. 만약 모든 방이 공유하는 채널에 이벤트를 발생시키면 1번방에서 a라는 유저가 참여를 눌러도 2번방에서 a가 참여했다는 이벤트가 잘못 동작할 수 있다. 각 방별로 채널을 구분시키기 위해서 고유한 값인 id를 통해 채널을 구분하도록 한다.



*views/chat_rooms/show.html.erb* 

* 각 방에 발생하는 이벤트를 받기 위해서 channel을 각자 방 채널로 맞춘다.

```erb
<script>
  function user_joined(data) {
    $('.joined_user_list').append(`<p class="user-${data.user_id}">${data.email}</p>`);
  }
  ...    
  var channel = pusher.subscribe('chat_room_<%= @chat_room.id %>');
  channel.bind('join', function(data){  //join이라는 이벤트가 발생했을때 실행해라
  console.log(data);
  user_joined(data);
   });
</script>
```



* 채팅 방에 글남기기(채팅하기)

```erb
...
<div class="chat_list">
<%  @chat_room.chats.each do |chat| %>
  <p><%= chat.user.email %>: <%= chat.messege %><small><%= chat.created_at %></small></p>
<% end %>
</div>
<%= form_tag("/chat_rooms/#{@chat_room.id}/chat", remote: true) do %>  <!--그 path로 post ajax로 넘어간다고? --> 
  <%= text_field_tag :messege %> 
<% end %>
...
```



*routes* 설정:  `member do`에 `post '/chat' => 'chat_rooms#chat'  `    추가



*controllers/chat_rooms_controller.rb*  : 

`before_action :set_chat_room, only: []`에 `:chat` 추가

```ruby
...
  def chat
    @chat_room.chats.create(user_id: current_user.id, messege: params[:messege])   
  end
...
```



*views/chat_rooms/chat.js.erb*  만들기

```erb
console.log("채팅함 ~");
$('#messege').val('');
```





*models/chat/rb*

```ruby
...
    def chat_messege_notification
        Pusher.trigger("chat_room_#{self.chat_room_id}","chat", self.as_json)  # pusher 이벤트 발생시킴
    end    
...
```

이벤트 발생시키는거 Pusher.trigger



*views/chat_rooms/show.html.erb*  : 추가

```erb
<script>
...
  function user_chat(data){
    $('.chat_list').append(`<p>[${data.user_id}] : ${data.messege} <small>(${data.created_at})</small></p>`);
  }

  var channel = pusher.subscribe('chat_room_<%= @chat_room.id %>'); //chatroom이라는 채널에 조인이라는 이벤트를 던진 admission 트리거로 간다.

  channel.bind('chat', function(data){
    user_chat(data);
  });
</script>
```



* 채팅방에 Join을 해야 채팅창이 보여야 한다.  

*views/chat_rooms/show.html.erb*

```erb
<% if current_user.joined_room?(@chat_room) %>
<div class="chat_list">
<%  @chat_room.chats.each do |chat| %>
  <p>[<%= chat.user.email %>]: <%= chat.messege %>  <small>(<%= chat.created_at %>)</small></p>
<% end %>
</div>
<%= form_tag("/chat_rooms/#{@chat_room.id}/chat", remote: true) do %>  <!--그 path로 post ajax로 넘어간다고? --> 
  <%= text_field_tag :messege %>
<% end %>
<hr>
<% end %>
```



* 채팅방 나가기



```erb
<%= link_to 'Exit', exit_chat_room_path(@chat_room), method: 'delete', remote: true, data: {confirm: "이 방을 나가시겠습니까?"} %>
<span class="exit_room"> |</span>
```



*routes*의 `member do`에 `delete '/exit' => 'chat_rooms#users_exit_room'` 추가하기 



*chat_rooms_controllers*

```ruby
...
def user_exit_room
    @chat_room.user_exit_room(current_user)
  end
...
```

*models/chat_room.rb*

```ruby
...
    def user_exit_room(user)
       Admission.where(user_id: user.id, chat_room_id: self.id)[0].destroy 
    end
...
```

`before_action :set_chat_room, only: []`에 `:user_exit_room` 추가



*views/chat_rooms/user_exit_room.js.erb* 추가하기 

```erb
alert("방 나왔당 ㅎㅎ;;");
location.reload();
```



*models/admission.rb* 

```ruby
...
    after_commit :user_exit_chat_room_notification, on: :
    
    def user_exit_chat_room_notification
       Pusher.trigger("chat_room_#{self.chat_room_id}", 'exit', self.as_join) 
    end
...
```



*views/chat_rooms/show.html.erb*

```erb
My-id : <%= current_user.email %><br/>
<h3> 이 방에 참여한 사람</h3>
<div class="joined_user_list">
<% @chat_room.users.each do |user| %>
    <p class="user-<%=user.id %>"><%= user.email %></p>
<% end %>
...
<script>
... 
  function user_exit(data){
    $(`.user-${data.user_id}`).remove();   //몇번유저인지 확인
    $('.chat_list').append(`<p>${data.email}님께서 퇴장하셨습니다.</p>`);
  }
  var channel = pusher.subscribe('chat_room_<%= @chat_room.id %>');
  channel.bind('exit', function(data){
    console.log(data);
    user_exit(data);
  });
...
</script>
```





```ruby
hanullllje:~/chat_app $ rails c

2.4.0 :001 > u=User.first    # 여기에 추가하기는 어렵다.
  User Load (0.5ms)  SELECT  "users".* FROM "users" ORDER BY "users"."id" ASC LIMIT ?  [["LIMIT", 1]]
 => #<User id: 1, email: "aa@aa.aa", created_at: "2018-07-10 01:55:33", updated_at: "2018-07-10 02:43:37">

2.4.0 :002 > u.as_json    # 조작하기 더 쉬워짐
 => {"id"=>1, "email"=>"aa@aa.aa", "created_at"=>Tue, 10 Jul 2018 01:55:33 UTC +00:00, "updated_at"=>Tue, 10 Jul 2018 02:43:37 UTC +00:00} 

2.4.0 :003 > Admission.first
  Admission Load (0.2ms)  SELECT  "admissions".* FROM "admissions" ORDER BY "admissions"."id" ASC LIMIT ?  [["LIMIT", 1]]
 => #<Admission id: 1, chat_room_id: 1, user_id: 1, created_at: "2018-07-10 01:56:34", updated_at: "2018-07-10 01:56:34"> 

2.4.0 :005 > a=Admission.first.as_json
  Admission Load (0.2ms)  SELECT  "admissions".* FROM "admissions" ORDER BY "admissions"."id" ASC LIMIT ?  [["LIMIT", 1]]
 => {"id"=>1, "chat_room_id"=>1, "user_id"=>1, "created_at"=>Tue, 10 Jul 2018 01:56:34 UTC +00:00, "updated_at"=>Tue, 10 Jul 2018 01:56:34 UTC +00:00} 

2.4.0 :013 > a.merge({email: "aa@aa.aa", title: "1234"})
 => {"id"=>1, "chat_room_id"=>1, "user_id"=>1, "created_at"=>Tue, 10 Jul 2018 01:56:34 UTC +00:00, "updated_at"=>Tue, 10 Jul 2018 01:56:34 UTC +00:00, :email=>"aa@aa.aa", :title=>"1234"} 
```

* json 형태로 바꾼 다음에 merge를 해줘야한다.



*models/admissions.rb*

```ruby
...
    after_commit :user_join_chat_room_notification, on: :create # create action이 발생했을때(commit) 동작해라 
    after_commit :user_exit_chat_room_notification, on: :destroy

    def user_join_chat_room_notification
       Pusher.trigger("chat_room_#{self.chat_room_id}", 'join', self.as_json.merge({email: self.user.email}))   # 수정
    end
    # chat_room을 고유하게 만들어주기 
    
    def user_exit_chat_room_notification
       Pusher.trigger("chat_room_#{self.chat_room_id}", 'exit', self.as_json.merge({email: self.user.email})) 
...
```





1. 현재 메인페이지(index)에서 방을 만들었을때 방 참석인원이 0명인 상태. 어제처럼 1로 증가하게 만든다.
2.  방제  수정/삭제 하는 경우에 index 에서 적용(pusher)될 수 있도록.
3.  방을 나왔을 때(Exit), 이방의 인원을 -1 해주는것 

