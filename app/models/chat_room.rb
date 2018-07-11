class ChatRoom < ApplicationRecord
    has_many :admissions
    has_many :users, through: :admissions
    has_many :chats
    
    after_commit :create_chat_room_notification, on: :create
    after_commit :update_chat_room_notification, on: :update 
    after_commit :destroy_chat_room_notification, on: :destroy
    
    def create_chat_room_notification
        Pusher.trigger("chat_room", 'create', self.as_json) # 나 자신을 json으로 보냄
        # (channel_name, event_name, data)
    end
    
    def update_chat_room_notification
        Pusher.trigger("chat_room", 'update', self.as_json) # 나 자신을 json으로 보냄
        # (channel_name, event_name, data)
    end
    
    def destroy_chat_room_notification
        Pusher.trigger("chat_room_#{self.id}", 'destroy', {})
        Pusher.trigger('chat_room', 'destroy', self.as_json)
    end
    
    def user_admit_room(user) # 인스턴스메소드 # 채팅방이 만들어지자마자 유저랑 채팅방을 연결
        # ChatRoom이 하나 만들어 지고 나면(commit) 다음 메소드를 같이 실행한다.
        Admission.create(user_id: user.id , chat_room_id: self.id)
    end
    
    def user_exit_room(user)
       Admission.where(user_id: user.id, chat_room_id: self.id)[0].destroy 
    end
    
end
