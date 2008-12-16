class Solr::Connection::Wrapper
  
  attr_reader :adapter, :opts
  
  # conection is instance of:
  #   Solr::Adapter::HTTP
  #   Solr::Adapter::Direct (jRuby only)
  def initialize(adapter, opts={})
    @adapter=adapter
    opts[:auto_commit]||=false
    opts[:global_params]||={}
    default_global_params = {
      :wt=>:ruby,
      :echoParams=>'EXPLICIT',
      :debugQuery=>true
    }
    opts[:global_params] = default_global_params.merge(opts[:global_params])
    @opts=opts
  end
  
  # sets default params etc.. - could be used as a mapping hook
  # type of request should be passed in here? -> map_params(:query, {})
  def map_params(params)
    opts[:global_params].dup.merge(params)
  end
  
  # send request to the select handler
  # params is hash with valid solr request params (:q, :fl, :qf etc..)
  #   if params[:wt] is not set, the default is :ruby (see opts[:global_params])
  #   if :wt is something other than :ruby, the raw response body is returned
  #   otherwise, an instance of Solr::Response::Query is returned
  #   NOTE: to get raw ruby, use :wt=>'ruby'
  def query(params)
    params = map_params(params)
    response = @adapter.query(params)
    params[:wt]==:ruby ? Solr::Response::Query.new(response) : response
  end
  
  # Finds a document by its id
  def find_by_id(id, params={})
    params = map_params(params)
    params[:q] = 'id:"#{id}"'
    query params
  end
  
  def index_info(params={})
    params = map_params(params)
    response = @adapter.index_info(params)
    params[:wt] == :ruby ? Solr::Response::IndexInfo.new(response) : response
  end
  
  # if :ruby is the :wt, then Solr::Response::Base is returned
  # -- there's not really a way to figure out what kind of handler request this is.
  
  def update(data, params={}, auto_commit=nil)
    params = map_params(params)
    response = @adapter.update(data, params)
    self.commit if auto_commit.nil? ? @opts[:auto_commit]==true : auto_commit
    params[:wt]==:ruby ? Solr::Response::Update.new(response) : response
  end
  
  def add(hash_or_array, opts={}, &block)
    update message.add(hash_or_array, opts, &block)
  end
  
  # send </commit>
  def commit(opts={})
    update message.commit, opts, false
  end
  
  # send </optimize>
  def optimize(opts={})
    update message.optimize, opts
  end
  
  # send </rollback>
  # NOTE: solr 1.4 only
  def rollback(opts={})
    update message.rollback, opts
  end
  
  # Delete one or many documents by id
  #   solr.delete_by_id 10
  #   solr.delete_by_id([12, 41, 199])
  def delete_by_id(ids, opts={})
    update message.delete_by_id(ids), opts
  end
  
  # delete one or many documents by query
  #   solr.delete_by_query 'available:0'
  #   solr.delete_by_query ['quantity:0', 'manu:"FQ"']
  def delete_by_query(queries, opts={})
    update message.delete_by_query(queries), opts
  end
  
  protected
  
  # shortcut to solr::message
  def message
    Solr::Message
  end
  
end