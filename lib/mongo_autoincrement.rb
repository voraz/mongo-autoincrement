# coding: utf-8
module MongoAutoincrement

  def self.included(model)
    class << model
      attr_accessor :autoincrement_key
      attr_accessor :autoincrement_zerofill
      attr_accessor :autoincrement_start
    end
    model.class_eval do
      model.extend( ClassMethods )
    end
  end

  module ClassMethods

    def has_autoincrement(source_key, options={})
      key source_key, Integer

      validates_uniqueness_of source_key
      before_validation :create_autoincrement

      self.autoincrement_key = source_key
      self.autoincrement_zerofill = options[:zerofill] || 0
      self.autoincrement_start = options[:start] || 1

      send :include, InstanceMethods
    end

  end

  module InstanceMethods
    def code
      "%0#{self.class.autoincrement_zerofill}d" % read_attribute(self.class.autoincrement_key) rescue nil
    end

    private
      def create_autoincrement
        autoincrement = get_succ

        while is_unique(autoincrement)==false || autoincrement.blank?
          autoincrement = get_succ
        end
        write_attribute(self.class.autoincrement_key, autoincrement)
      end

      def get_succ
        self.class.count==0 ? self.class.autoincrement_start : self.class.first(:select=>self.class.autoincrement_key.to_s, :order=>"#{self.class.autoincrement_key.to_s} desc").code.succ.to_i
      end

      def is_unique(current_code)
        similars = self.class.all( self.class.autoincrement_key=>current_code )
        similars.include?(self) || similars.blank?
      end

  end

end

